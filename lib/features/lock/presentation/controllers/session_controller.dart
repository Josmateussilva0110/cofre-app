import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/feedback/toast_controller.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/security/lock_suspension.dart';
import '../../../../core/security/secret_policy.dart';
import '../../../../core/security/vault_key.dart';
import '../../../../core/services/device_clock.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/biometric_key_store.dart';
import '../../domain/unlock_attempts.dart';
import '../../domain/vault_key_repository.dart';

/// Ainda não há chave mestre (primeiro uso ou cofre apagado) ou há uma chave a conferir.
enum LockMode { createKey, enterKey }

enum MasterKeyError { requirementsMissing, mismatch, wrongKey, lockedOut }

/// Estado da sessão: criação e verificação da chave mestre, digital, bloqueio por inatividade ou em segundo plano e
/// limite de tentativas.
///
/// É dona da chave do cofre enquanto está desbloqueada: entrega a chave em [_onUnlocked] e a descarta ao bloquear.
class SessionController extends ChangeNotifier with WidgetsBindingObserver {
  SessionController({
    required this._keys,
    required this._toast,
    required this._autoLockMinutes,
    required this._biometricsEnabled,
    required this._setBiometricsEnabled,
    required this._onUnlocked,
    required this._onLocked,
    LockSuspension? lockSuspension,
    DeviceClock? deviceClock,
    DateTime Function() clock = DateTime.now,
  }) : _lockSuspension = lockSuspension ?? LockSuspension(),
       _deviceClock = deviceClock ?? PlatformDeviceClock(),
       _clock = clock,
       _lastActivity = clock();

  static const _lockoutTick = Duration(seconds: 1);

  static const _unlockPrompt = BiometricPromptTexts(
    title: AppStrings.biometricUnlockTitle,
    subtitle: AppStrings.biometricUnlockSubtitle,
    cancel: AppStrings.biometricUseMasterKey,
  );
  static const _enablePrompt = BiometricPromptTexts(
    title: AppStrings.biometricEnableTitle,
    subtitle: AppStrings.biometricEnableSubtitle,
    cancel: AppStrings.cancel,
  );

  final VaultKeyRepository _keys;
  final ToastController _toast;
  final int Function() _autoLockMinutes;
  final bool Function() _biometricsEnabled;
  final void Function(bool enabled) _setBiometricsEnabled;
  final Future<void> Function(VaultKey key) _onUnlocked;
  final VoidCallback _onLocked;
  final LockSuspension _lockSuspension;

  /// Conta a espera depois de erros (não pode ser burlado adiantando a data). [_clock] serve ao resto.
  final DeviceClock _deviceClock;
  final DateTime Function() _clock;

  KeySetup _setup = KeySetup.none;
  VaultKey? _vaultKey;
  bool _isScanning = false;
  bool _isBusy = false;
  bool _hasBiometricOffer = false;
  bool _isStorageUnavailable = false;
  MasterKeyError? _keyError;
  List<SecretRequirement> _missingRequirements = const [];
  UnlockAttempts _attempts = const UnlockAttempts();
  DateTime _lastActivity;

  /// Quando o app foi para segundo plano com o cofre aberto (null se está em primeiro plano).
  DateTime? _leftAppAt;
  bool _isObservingLifecycle = false;
  Timer? _idleTimer;
  Timer? _lockoutTimer;

  bool get isLocked => _vaultKey == null;

  /// O armazenamento seguro do aparelho (Keystore) não respondeu: não dá para saber se há chave nem conferi-la.
  bool get isStorageUnavailable => _isStorageUnavailable;
  bool get isScanning => _isScanning;

  /// Verificando ou criando a chave (a derivação leva alguns segundos).
  bool get isBusy => _isBusy;
  LockMode get mode => _setup == KeySetup.none ? LockMode.createKey : LockMode.enterKey;
  bool get biometricsEnabled => _biometricsEnabled();

  /// A tela deve perguntar se o usuário quer ativar a digital e responder com [acceptBiometricOffer] ou
  /// [declineBiometricOffer]. O sensor só é acionado depois do "sim", para o pedido não pegar ninguém de surpresa.
  bool get hasBiometricOffer => _hasBiometricOffer;

  /// Tempo até poder tentar de novo, ou null se não há bloqueio.
  Duration? get lockoutRemaining => _attempts.remainingLockout(_deviceClock.now());

  /// O que faltou na última chave mestre recusada ([MasterKeyError.requirementsMissing]).
  List<SecretRequirement> get missingRequirements => _missingRequirements;

  MasterKeyError? get keyError => lockoutRemaining != null ? MasterKeyError.lockedOut : _keyError;

  /// Também serve para tentar de novo depois de [isStorageUnavailable].
  Future<void> load() async {
    try {
      await _deviceClock.sync();
      _setup = await _keys.setup();
      final attempts = await _keys.loadAttempts();
      _attempts = attempts.reanchored(_deviceClock.now());
      if (!identical(_attempts, attempts)) await _saveAttempts(_attempts);
      _isStorageUnavailable = false;
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.load', error, stackTrace);
      _isStorageUnavailable = true;
    }
    _syncLockoutTimer();
    notifyListeners();
  }

  /// Começa a vigiar a inatividade e a saída do app.
  void start() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(AppConfig.idleCheckInterval, (_) => _checkIdle());
    if (_isObservingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _isObservingLifecycle = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        if (isLocked || _lockSuspension.isActive) return;
        _leftAppAt ??= _clock();
      case AppLifecycleState.resumed:
        // Os timers podem ficar parados em segundo plano: confere ao voltar, antes de mostrar o cofre.
        _lockIfAwayTooLong();
        _leftAppAt = null;
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Chamado a cada toque na tela.
  void registerActivity() => _lastActivity = _clock();

  void lock({String? message}) {
    final key = _vaultKey;
    _vaultKey = null;
    _leftAppAt = null;
    _onLocked();
    key?.destroy();
    _isScanning = false;
    _hasBiometricOffer = false;
    _keyError = null;
    notifyListeners();
    if (message != null) _toast.show(message);
  }

  /// Define a primeira chave mestre e desbloqueia. Retorna true se criou.
  Future<bool> createMasterKey(String masterKey, String confirmation) async {
    if (_isBusy || mode != LockMode.createKey) return false;
    final missing = SecretPolicy.missing(masterKey, minLength: AppConfig.minMasterKeyLength);
    if (missing.isNotEmpty) {
      _missingRequirements = missing;
      return _fail(MasterKeyError.requirementsMissing);
    }
    if (masterKey != confirmation) return _fail(MasterKeyError.mismatch);

    _setBusy(true);
    final VaultKey key;
    try {
      key = await _keys.create(masterKey);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.createMasterKey', error, stackTrace);
      _setBusy(false);
      _toast.show(AppStrings.saveFailed);
      return false;
    }
    _setup = KeySetup.ready;
    if (!await _completeUnlock(key)) return false;
    _toast.show(AppStrings.masterKeyCreated);
    _offerBiometricsIfNeeded();
    return true;
  }

  /// Confere a chave e desbloqueia. Retorna true se desbloqueou.
  Future<bool> unlockWithKey(String masterKey) async {
    if (_isBusy || mode != LockMode.enterKey) return false;
    if (lockoutRemaining != null) return false;
    if (masterKey.isEmpty) return _fail(MasterKeyError.wrongKey);

    _setBusy(true);
    final VaultKey? key;
    try {
      key = await _keyFor(masterKey);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.unlockWithKey', error, stackTrace);
      _setBusy(false);
      return _fail(MasterKeyError.wrongKey);
    }

    if (key == null) {
      _isBusy = false;
      await _saveAttempts(_attempts.registerFailure(_deviceClock.now()));
      _syncLockoutTimer();
      return _fail(MasterKeyError.wrongKey);
    }
    if (_attempts.failures > 0) await _saveAttempts(const UnlockAttempts());
    if (!await _completeUnlock(key)) return false;
    _offerBiometricsIfNeeded();
    return true;
  }

  Future<void> unlockWithBiometrics() async {
    if (mode != LockMode.enterKey || _isScanning || _isBusy) return;
    if (!_biometricsEnabled()) return _toast.show(AppStrings.biometricDisabledInSettings);
    if (!await _keys.hasBiometricKey()) return _toast.show(AppStrings.biometricNeedsMasterKey);

    _isScanning = true;
    notifyListeners();
    try {
      final key = await _keys.unlockWithBiometrics(_unlockPrompt);
      _isScanning = false;
      // O usuário pode ter desbloqueado com a chave enquanto a digital era lida.
      if (!isLocked) return key.destroy();
      if (await _completeUnlock(key)) _toast.show(AppStrings.biometricRecognized);
    } on BiometricKeyFailure catch (failure) {
      _isScanning = false;
      notifyListeners();
      final message = _messageFor(failure.reason);
      if (message != null) _toast.show(message);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.unlockWithBiometrics', error, stackTrace);
      _isScanning = false;
      notifyListeners();
      _toast.show(AppStrings.biometricUnavailable);
    }
  }

  /// Liga ou desliga a digital (Ajustes). Ligar pede um toque no sensor. Retorna o estado final.
  Future<bool> setBiometrics({required bool enabled}) async {
    if (!enabled) {
      await _keys.disableBiometrics();
      _setBiometricsEnabled(false);
      return false;
    }
    final key = _vaultKey;
    if (key == null) return false;
    try {
      await _keys.enableBiometrics(key, _enablePrompt);
    } on BiometricKeyFailure catch (failure) {
      final message = _messageFor(failure.reason);
      if (message != null) _toast.show(message);
      return false;
    }
    _setBiometricsEnabled(true);
    _toast.show(AppStrings.biometricEnabled);
    return true;
  }

  /// Apaga a chave mestre e bloqueia; o próximo desbloqueio pede uma chave nova. Usado junto com apagar o cofre.
  Future<void> resetMasterKey({String? message}) async {
    await _keys.clear();
    _setup = KeySetup.none;
    _attempts = const UnlockAttempts();
    _syncLockoutTimer();
    lock(message: message);
  }

  void clearKeyError() {
    if (_keyError == null) return;
    _keyError = null;
    notifyListeners();
  }

  /// Na versão anterior só havia o hash: confere e já cria a chave do cofre (migração, uma única vez).
  Future<VaultKey?> _keyFor(String masterKey) async {
    if (_setup != KeySetup.legacyHash) return _keys.unlock(masterKey);
    if (!await _keys.verifyLegacy(masterKey)) return null;
    final key = await _keys.create(masterKey);
    _setup = KeySetup.ready;
    return key;
  }

  /// Abre o cofre com a chave. Se a leitura falhar (ex.: erro de disco), descarta a chave e continua bloqueado.
  Future<bool> _completeUnlock(VaultKey key) async {
    try {
      await _onUnlocked(key);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.completeUnlock', error, stackTrace);
      _onLocked();
      key.destroy();
      _isBusy = false;
      notifyListeners();
      _toast.show(AppStrings.vaultOpenFailed);
      return false;
    }
    registerActivity();
    _vaultKey = key;
    _isBusy = false;
    _keyError = null;
    notifyListeners();
    return true;
  }

  /// Se a digital está ligada nas preferências mas não há chave protegida por ela (primeiro uso, migração ou
  /// digital nova no aparelho), sinaliza [hasBiometricOffer] para a tela perguntar.
  void _offerBiometricsIfNeeded() {
    unawaited(() async {
      try {
        if (!_biometricsEnabled() || await _keys.hasBiometricKey()) return;
        if (await _keys.biometricAvailability() != BiometricAvailability.available) {
          // Sem leitor ou sem digital cadastrada: não há o que oferecer agora. Dá para ligar em Ajustes depois.
          _setBiometricsEnabled(false);
          return;
        }
        if (isLocked) return;
        _hasBiometricOffer = true;
        notifyListeners();
      } on Object catch (error, stackTrace) {
        AppLogger.error('SessionController.offerBiometrics', error, stackTrace);
      }
    }());
  }

  /// O usuário aceitou: pede a digital e protege uma cópia da chave do cofre por ela.
  Future<void> acceptBiometricOffer() async {
    final key = _vaultKey;
    if (!_takeBiometricOffer() || key == null) return;
    try {
      await _keys.enableBiometrics(key, _enablePrompt);
      _toast.show(AppStrings.biometricEnabled);
    } on BiometricKeyFailure catch (failure) {
      _setBiometricsEnabled(false);
      _toast.show(_messageFor(failure.reason) ?? AppStrings.biometricDeclined);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.acceptBiometricOffer', error, stackTrace);
      _setBiometricsEnabled(false);
      _toast.show(AppStrings.biometricUnavailable);
    }
  }

  /// O usuário recusou ("Agora não"): desliga a digital para não perguntar de novo.
  void declineBiometricOffer() {
    if (!_takeBiometricOffer()) return;
    _setBiometricsEnabled(false);
    _toast.show(AppStrings.biometricDeclined);
  }

  // Consome a oferta. Falso se não havia oferta ou o cofre foi bloqueado enquanto o diálogo estava aberto.
  bool _takeBiometricOffer() {
    if (!_hasBiometricOffer || isLocked) return false;
    _hasBiometricOffer = false;
    notifyListeners();
    return true;
  }

  bool _fail(MasterKeyError error) {
    _keyError = error;
    notifyListeners();
    return false;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  Future<void> _saveAttempts(UnlockAttempts attempts) async {
    _attempts = attempts;
    try {
      await _keys.saveAttempts(attempts);
    } on Object catch (error, stackTrace) {
      // O limite continua valendo em memória enquanto o app estiver aberto.
      AppLogger.error('SessionController.saveAttempts', error, stackTrace);
    }
  }

  // Enquanto há bloqueio por tentativas, atualiza a contagem regressiva a cada segundo.
  void _syncLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    if (lockoutRemaining == null) return;
    _lockoutTimer = Timer.periodic(_lockoutTick, (_) {
      if (lockoutRemaining == null) {
        _lockoutTimer?.cancel();
        _lockoutTimer = null;
        _keyError = null;
      }
      notifyListeners();
    });
  }

  void _checkIdle() {
    if (isLocked) return;
    _lockIfAwayTooLong();
    final minutes = _autoLockMinutes();
    if (isLocked || minutes <= 0) return;
    if (_clock().difference(_lastActivity) > Duration(minutes: minutes)) {
      lock(message: AppStrings.lockedByInactivity);
    }
  }

  // Vale mesmo com o bloqueio por inatividade em "nunca".
  void _lockIfAwayTooLong() {
    final leftAt = _leftAppAt;
    if (isLocked || leftAt == null) return;
    if (_clock().difference(leftAt) >= AppConfig.backgroundLockDelay) lock(message: AppStrings.lockedInBackground);
  }

  /// Null quando não há o que avisar (o usuário cancelou).
  static String? _messageFor(BiometricKeyFailureReason reason) => switch (reason) {
    BiometricKeyFailureReason.canceled => null,
    BiometricKeyFailureReason.invalidated => AppStrings.biometricInvalidated,
    BiometricKeyFailureReason.missing => AppStrings.biometricNeedsMasterKey,
    BiometricKeyFailureReason.notEnrolled => AppStrings.biometricNotEnrolled,
    BiometricKeyFailureReason.noHardware => AppStrings.biometricNoHardware,
    BiometricKeyFailureReason.lockedOut => AppStrings.biometricLockedOut,
    BiometricKeyFailureReason.unavailable => AppStrings.biometricUnavailable,
  };

  @override
  void dispose() {
    if (_isObservingLifecycle) WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _lockoutTimer?.cancel();
    _vaultKey?.destroy();
    super.dispose();
  }
}
