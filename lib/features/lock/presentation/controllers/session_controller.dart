import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/feedback/toast_controller.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/biometric_authenticator.dart';
import '../../domain/master_key_repository.dart';
import '../../domain/unlock_attempts.dart';

/// Ainda não há chave mestre (primeiro uso ou cofre apagado) ou há uma chave a conferir.
enum LockMode { createKey, enterKey }

enum MasterKeyError { tooShort, mismatch, wrongKey, lockedOut }

/// Estado da sessão: criação e verificação da chave mestre, digital, bloqueio por inatividade e limite de tentativas.
class SessionController extends ChangeNotifier {
  SessionController({
    required this._authenticator,
    required this._masterKeys,
    required this._toast,
    required this._autoLockMinutes,
    required this._biometricsEnabled,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock,
       _lastActivity = clock();

  static const _lockoutTick = Duration(seconds: 1);

  final BiometricAuthenticator _authenticator;
  final MasterKeyRepository _masterKeys;
  final ToastController _toast;
  final int Function() _autoLockMinutes;
  final bool Function() _biometricsEnabled;
  final DateTime Function() _clock;

  bool _hasMasterKey = false;
  bool _isLocked = true;
  bool _isScanning = false;
  bool _isBusy = false;
  MasterKeyError? _keyError;
  UnlockAttempts _attempts = const UnlockAttempts();
  DateTime _lastActivity;
  Timer? _idleTimer;
  Timer? _lockoutTimer;

  bool get isLocked => _isLocked;
  bool get isScanning => _isScanning;

  /// Verificando ou criando a chave (a derivação leva alguns segundos).
  bool get isBusy => _isBusy;
  LockMode get mode => _hasMasterKey ? LockMode.enterKey : LockMode.createKey;
  bool get biometricsEnabled => _biometricsEnabled();

  /// Tempo até poder tentar de novo, ou null se não há bloqueio.
  Duration? get lockoutRemaining => _attempts.remainingLockout(_clock());

  MasterKeyError? get keyError => lockoutRemaining != null ? MasterKeyError.lockedOut : _keyError;

  Future<void> load() async {
    _hasMasterKey = await _masterKeys.hasKey();
    _attempts = await _masterKeys.loadAttempts();
    _syncLockoutTimer();
    notifyListeners();
  }

  /// Começa a vigiar a inatividade.
  void start() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(AppConfig.idleCheckInterval, (_) => _checkIdle());
  }

  /// Chamado a cada toque na tela.
  void registerActivity() => _lastActivity = _clock();

  void lock({String? message}) {
    _isLocked = true;
    _isScanning = false;
    _keyError = null;
    notifyListeners();
    if (message != null) _toast.show(message);
  }

  /// Define a primeira chave mestre e desbloqueia. Retorna true se criou.
  Future<bool> createMasterKey(String key, String confirmation) async {
    if (_isBusy || _hasMasterKey) return false;
    if (key.length < AppConfig.minMasterKeyLength) return _fail(MasterKeyError.tooShort);
    if (key != confirmation) return _fail(MasterKeyError.mismatch);

    _setBusy(true);
    try {
      await _masterKeys.setKey(key);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.createMasterKey', error, stackTrace);
      _setBusy(false);
      _toast.show(AppStrings.saveFailed);
      return false;
    }
    _hasMasterKey = true;
    _isBusy = false;
    _unlock();
    _toast.show(AppStrings.masterKeyCreated);
    return true;
  }

  /// Confere a chave e desbloqueia. Retorna true se desbloqueou.
  Future<bool> unlockWithKey(String key) async {
    if (_isBusy || !_hasMasterKey) return false;
    if (lockoutRemaining != null) return false;
    if (key.isEmpty) return _fail(MasterKeyError.wrongKey);

    _setBusy(true);
    final bool matches;
    try {
      matches = await _masterKeys.verify(key);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.unlockWithKey', error, stackTrace);
      _setBusy(false);
      return _fail(MasterKeyError.wrongKey);
    }
    _isBusy = false;

    if (!matches) {
      await _saveAttempts(_attempts.registerFailure(_clock()));
      _syncLockoutTimer();
      return _fail(MasterKeyError.wrongKey);
    }
    if (_attempts.failures > 0) await _saveAttempts(const UnlockAttempts());
    _unlock();
    return true;
  }

  /// Apaga a chave mestre e bloqueia; o próximo desbloqueio pede uma chave nova. Usado junto com apagar o cofre.
  Future<void> resetMasterKey({String? message}) async {
    await _masterKeys.clear();
    _hasMasterKey = false;
    _attempts = const UnlockAttempts();
    _syncLockoutTimer();
    lock(message: message);
  }

  void clearKeyError() {
    if (_keyError == null) return;
    _keyError = null;
    notifyListeners();
  }

  Future<void> unlockWithBiometrics() async {
    // A digital é um atalho para quem já tem chave mestre; ela não substitui a criação da chave.
    if (!_hasMasterKey) return;
    if (!_biometricsEnabled()) return _toast.show(AppStrings.biometricDisabledInSettings);
    if (_isScanning || _isBusy) return;
    _isScanning = true;
    notifyListeners();

    var recognized = false;
    String? failureMessage;
    try {
      recognized = await _authenticator.authenticate(reason: AppStrings.biometricPrompt);
    } on BiometricFailure catch (failure) {
      failureMessage = _messageFor(failure.reason);
    } on Object catch (error, stackTrace) {
      AppLogger.error('SessionController.unlockWithBiometrics', error, stackTrace);
      failureMessage = AppStrings.biometricUnavailable;
    }

    _isScanning = false;
    // O usuário pode ter desbloqueado com a chave enquanto a digital era lida.
    if (!_isLocked) return notifyListeners();
    if (recognized) {
      _unlock();
      _toast.show(AppStrings.biometricRecognized);
    } else {
      notifyListeners();
      if (failureMessage != null) _toast.show(failureMessage);
    }
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
      await _masterKeys.saveAttempts(attempts);
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

  void _unlock() {
    registerActivity();
    _isLocked = false;
    _keyError = null;
    notifyListeners();
  }

  void _checkIdle() {
    final minutes = _autoLockMinutes();
    if (_isLocked || minutes <= 0) return;
    if (_clock().difference(_lastActivity) > Duration(minutes: minutes)) {
      lock(message: AppStrings.lockedByInactivity);
    }
  }

  static String _messageFor(BiometricFailureReason reason) => switch (reason) {
    BiometricFailureReason.notEnrolled => AppStrings.biometricNotEnrolled,
    BiometricFailureReason.noHardware => AppStrings.biometricNoHardware,
    BiometricFailureReason.lockedOut => AppStrings.biometricLockedOut,
    BiometricFailureReason.unavailable => AppStrings.biometricUnavailable,
  };

  @override
  void dispose() {
    _idleTimer?.cancel();
    _lockoutTimer?.cancel();
    super.dispose();
  }
}
