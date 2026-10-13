import 'dart:async';
import 'dart:io';

import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/core/feedback/toast_controller.dart';
import 'package:cofre/core/security/lock_suspension.dart';
import 'package:cofre/core/security/secret_policy.dart';
import 'package:cofre/core/security/vault_key.dart';
import 'package:cofre/core/services/device_clock.dart';
import 'package:cofre/features/lock/domain/biometric_key_store.dart';
import 'package:cofre/features/lock/presentation/controllers/session_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ToastController toast;
  late FakeBiometricKeyStore biometrics;
  late InMemoryKeyValueStore store;
  late bool biometricsEnabled;
  var autoLockMinutes = 5;
  VaultKey? openedWith;
  var closeCalls = 0;

  SessionController create({DateTime Function()? clock, DeviceClock? deviceClock, LockSuspension? lockSuspension}) =>
      SessionController(
        keys: vaultKeyRepository(store, biometrics),
        toast: toast,
        autoLockMinutes: () => autoLockMinutes,
        biometricsEnabled: () => biometricsEnabled,
        setBiometricsEnabled: (enabled) => biometricsEnabled = enabled,
        onUnlocked: (key) async => openedWith = key,
        onLocked: () => closeCalls++,
        lockSuspension: lockSuspension,
        deviceClock: deviceClock ?? FakeDeviceClock(clock ?? DateTime.now),
        clock: clock ?? DateTime.now,
      );

  Future<SessionController> createWithKey({bool withBiometrics = true}) async {
    final key = await vaultKeyRepository(store, biometrics).create(testMasterKey);
    if (withBiometrics) await vaultKeyRepository(store, biometrics).enableBiometrics(key, testPrompt);
    final session = create();
    await session.load();
    return session;
  }

  setUp(() {
    toast = ToastController();
    biometrics = FakeBiometricKeyStore();
    store = InMemoryKeyValueStore();
    biometricsEnabled = true;
    autoLockMinutes = 5;
    openedWith = null;
    closeCalls = 0;
  });

  group('primeiro uso', () {
    test('sem chave salva, pede para criar', () async {
      final session = create();
      await session.load();
      expect(session.mode, LockMode.createKey);
    });

    test('valida tamanho e confirmação antes de criar', () async {
      final session = create();
      await session.load();
      expect(await session.createMasterKey('Curta1!', 'Curta1!'), isFalse);
      expect(session.keyError, MasterKeyError.requirementsMissing);
      expect(session.missingRequirements, [SecretRequirement.minLength]);
      expect(await session.createMasterKey('123456789012', '123456789012'), isFalse);
      expect(session.missingRequirements, [
        SecretRequirement.uppercase,
        SecretRequirement.lowercase,
        SecretRequirement.symbol,
      ]);
      expect(await session.createMasterKey('Chave-longa-1', 'Chave-outra-1'), isFalse);
      expect(session.keyError, MasterKeyError.mismatch);
    });

    test('cria a chave, entrega a chave do cofre e oferece a digital sem acionar o sensor', () async {
      final session = create();
      await session.load();
      expect(await session.createMasterKey(testMasterKey, testMasterKey), isTrue);
      expect(session.isLocked, isFalse);
      expect(openedWith, isNotNull);
      expect(session.mode, LockMode.enterKey);
      await pumpEventQueue();
      expect(session.hasBiometricOffer, isTrue);
      expect(biometrics.prompts, 0);
      expect(store.values.containsKey(AppConfig.biometricVaultKeyStorageKey), isFalse);

      await session.acceptBiometricOffer();
      expect(session.hasBiometricOffer, isFalse);
      expect(biometrics.prompts, 1);
      expect(store.values.containsKey(AppConfig.biometricVaultKeyStorageKey), isTrue);
      expect(toast.message, 'Digital ativada');
    });

    test('recusar a oferta desliga a digital sem acionar o sensor', () async {
      final session = create();
      await session.load();
      await session.createMasterKey(testMasterKey, testMasterKey);
      await pumpEventQueue();

      session.declineBiometricOffer();
      expect(session.hasBiometricOffer, isFalse);
      expect(biometricsEnabled, isFalse);
      expect(biometrics.prompts, 0);
      expect(toast.message, 'Digital desativada. Ative em Ajustes quando quiser.');
    });

    test('cancelar o sensor depois de aceitar também desliga a digital', () async {
      final session = create();
      await session.load();
      await session.createMasterKey(testMasterKey, testMasterKey);
      await pumpEventQueue();

      biometrics.nextFailure = BiometricKeyFailureReason.canceled;
      await session.acceptBiometricOffer();
      expect(biometricsEnabled, isFalse);
      expect(store.values.containsKey(AppConfig.biometricVaultKeyStorageKey), isFalse);
      expect(toast.message, 'Digital desativada. Ative em Ajustes quando quiser.');
    });

    test('aparelho sem digital disponível não recebe a oferta', () async {
      biometrics.availabilityResult = BiometricAvailability.notEnrolled;
      final session = create();
      await session.load();
      await session.createMasterKey(testMasterKey, testMasterKey);
      await pumpEventQueue();
      expect(session.hasBiometricOffer, isFalse);
      expect(biometricsEnabled, isFalse);
      expect(biometrics.prompts, 0);
    });

    test('bloquear descarta a oferta pendente', () async {
      final session = create();
      await session.load();
      await session.createMasterKey(testMasterKey, testMasterKey);
      await pumpEventQueue();

      session.lock();
      expect(session.hasBiometricOffer, isFalse);
      await session.acceptBiometricOffer();
      session.declineBiometricOffer();
      expect(biometrics.prompts, 0);
      expect(biometricsEnabled, isTrue);
    });

    test('digital não desbloqueia antes de existir chave', () async {
      final session = create();
      await session.load();
      await session.unlockWithBiometrics();
      expect(biometrics.prompts, 0);
      expect(session.isLocked, isTrue);
    });
  });

  group('chave existente', () {
    test('chave certa desbloqueia; errada mostra erro', () async {
      final session = await createWithKey();
      expect(await session.unlockWithKey('chave-errada'), isFalse);
      expect(session.keyError, MasterKeyError.wrongKey);
      expect(openedWith, isNull);
      expect(await session.unlockWithKey(testMasterKey), isTrue);
      expect(session.isLocked, isFalse);
      expect(openedWith, isNotNull);
    });

    test('bloquear fecha o cofre e zera a chave', () async {
      final session = await createWithKey();
      await session.unlockWithKey(testMasterKey);
      final key = openedWith!;
      session.lock();
      expect(closeCalls, 1);
      expect(() => key.bytes, throwsStateError);
    });

    test('após 5 erros bloqueia novas tentativas, inclusive com a chave certa', () {
      fakeAsync((async) {
        vaultKeyRepository(store, biometrics).create(testMasterKey);
        async.flushMicrotasks();
        final session = create(clock: () => async.getClock(DateTime(2026)).now())..load();
        async.flushMicrotasks();

        for (var i = 0; i < 5; i++) {
          session.unlockWithKey('errada-$i');
          async.flushMicrotasks();
        }
        expect(session.keyError, MasterKeyError.lockedOut);
        expect(session.lockoutRemaining, const Duration(seconds: 30));

        session.unlockWithKey(testMasterKey);
        async.flushMicrotasks();
        expect(session.isLocked, isTrue);

        async.elapse(const Duration(seconds: 31));
        expect(session.keyError, isNull);
        session.unlockWithKey(testMasterKey);
        async.flushMicrotasks();
        expect(session.isLocked, isFalse);
        session.dispose();
        toast.dispose();
      });
    });

    test('o bloqueio sobrevive a reabrir o app', () {
      fakeAsync((async) {
        DateTime now() => async.getClock(DateTime(2026)).now();
        vaultKeyRepository(store, biometrics).create(testMasterKey);
        async.flushMicrotasks();
        final first = create(clock: now)..load();
        async.flushMicrotasks();
        for (var i = 0; i < 5; i++) {
          first.unlockWithKey('errada');
          async.flushMicrotasks();
        }
        first.dispose();

        final reopened = create(clock: now)..load();
        async.flushMicrotasks();
        expect(reopened.lockoutRemaining, isNotNull);
        reopened.dispose();
        toast.dispose();
      });
    });

    test('adiantar a data do sistema não encurta o bloqueio', () {
      fakeAsync((async) {
        var wallOffset = Duration.zero;
        DateTime monotonic() => async.getClock(DateTime(2026)).now();
        vaultKeyRepository(store, biometrics).create(testMasterKey);
        async.flushMicrotasks();
        final session = create(clock: () => monotonic().add(wallOffset), deviceClock: FakeDeviceClock(monotonic))
          ..load();
        async.flushMicrotasks();
        for (var i = 0; i < 5; i++) {
          session.unlockWithKey('errada-$i');
          async.flushMicrotasks();
        }

        wallOffset = const Duration(days: 1);
        expect(session.lockoutRemaining, const Duration(seconds: 30));
        session.unlockWithKey(testMasterKey);
        async.flushMicrotasks();
        expect(session.isLocked, isTrue);
        session.dispose();
        toast.dispose();
      });
    });

    test('reiniciar o aparelho recomeça a espera', () {
      fakeAsync((async) {
        DateTime now() => async.getClock(DateTime(2026)).now();
        final device = FakeDeviceClock(now);
        vaultKeyRepository(store, biometrics).create(testMasterKey);
        async.flushMicrotasks();
        final first = create(clock: now, deviceClock: device)..load();
        async.flushMicrotasks();
        for (var i = 0; i < 5; i++) {
          first.unlockWithKey('errada');
          async.flushMicrotasks();
        }
        first.dispose();

        async.elapse(const Duration(seconds: 25));
        device.bootId++;
        final reopened = create(clock: now, deviceClock: device)..load();
        async.flushMicrotasks();
        expect(reopened.lockoutRemaining, const Duration(seconds: 30));
        reopened.dispose();
        toast.dispose();
      });
    });

    test('redefinir a chave volta para o modo de criação', () async {
      final session = await createWithKey();
      await session.unlockWithKey(testMasterKey);
      await session.resetMasterKey();
      expect(session.isLocked, isTrue);
      expect(session.mode, LockMode.createKey);
      expect(store.values, isEmpty);
    });
  });

  group('digital', () {
    test('reconhecida desbloqueia com a mesma chave do cofre', () async {
      final session = await createWithKey();
      await session.unlockWithBiometrics();
      expect(session.isLocked, isFalse);
      expect(openedWith, isNotNull);
      expect(toast.message, 'Digital reconhecida');
    });

    test('cancelada não mostra aviso e mantém bloqueado', () async {
      final session = await createWithKey();
      biometrics.nextFailure = BiometricKeyFailureReason.canceled;
      await session.unlockWithBiometrics();
      expect(session.isLocked, isTrue);
      expect(session.isScanning, isFalse);
      expect(toast.message, isNull);
    });

    test('sem chave protegida pela digital, pede a chave mestre', () async {
      final session = await createWithKey(withBiometrics: false);
      await session.unlockWithBiometrics();
      expect(biometrics.prompts, 0);
      expect(toast.message, 'Use a chave mestre uma vez para ativar a digital.');
    });

    test('desativada em Ajustes não chama o leitor', () async {
      biometricsEnabled = false;
      final session = await createWithKey();
      final before = biometrics.prompts;
      await session.unlockWithBiometrics();
      expect(biometrics.prompts, before);
    });

    test('ligar em Ajustes exige cofre aberto e um toque; desligar apaga', () async {
      final session = await createWithKey(withBiometrics: false);
      biometricsEnabled = false;
      expect(await session.setBiometrics(enabled: true), isFalse);

      await session.unlockWithKey(testMasterKey);
      expect(await session.setBiometrics(enabled: true), isTrue);
      expect(biometricsEnabled, isTrue);

      expect(await session.setBiometrics(enabled: false), isFalse);
      expect(biometricsEnabled, isFalse);
      expect(store.values.containsKey(AppConfig.biometricVaultKeyStorageKey), isFalse);
    });
  });

  /// Sessão desbloqueada com relógio falso; libera tudo ao terminar [body].
  void unlockedSession(
    FakeAsync async,
    void Function(SessionController session) body, {
    LockSuspension? lockSuspension,
  }) {
    vaultKeyRepository(store, biometrics).create(testMasterKey);
    async.flushMicrotasks();
    final session = create(clock: () => async.getClock(DateTime(2026)).now(), lockSuspension: lockSuspension)
      ..load()
      ..start();
    async.flushMicrotasks();
    session.unlockWithKey(testMasterKey);
    async.flushMicrotasks();
    body(session);
    session.dispose();
    toast.dispose();
  }

  group('falhas de leitura', () {
    test('armazenamento seguro indisponível: avisa e permite tentar de novo', () async {
      await vaultKeyRepository(store, biometrics).create(testMasterKey);
      final broken = FailingKeyValueStore(store);
      final session = SessionController(
        keys: vaultKeyRepository(broken, biometrics),
        toast: toast,
        autoLockMinutes: () => autoLockMinutes,
        biometricsEnabled: () => biometricsEnabled,
        setBiometricsEnabled: (enabled) => biometricsEnabled = enabled,
        onUnlocked: (key) async => openedWith = key,
        onLocked: () => closeCalls++,
        deviceClock: FakeDeviceClock(DateTime.now),
      );
      await session.load();
      expect(session.isStorageUnavailable, isTrue);
      // Nada foi apagado: o erro não é tratado como "sem chave".
      expect(store.values.containsKey(AppConfig.vaultKeyStorageKey), isTrue);

      broken.isFailing = false;
      await session.load();
      expect(session.isStorageUnavailable, isFalse);
      expect(session.mode, LockMode.enterKey);
    });

    test('erro ao abrir o cofre descarta a chave e continua bloqueado', () async {
      await vaultKeyRepository(store, biometrics).create(testMasterKey);
      VaultKey? received;
      final session = SessionController(
        keys: vaultKeyRepository(store, biometrics),
        toast: toast,
        autoLockMinutes: () => autoLockMinutes,
        biometricsEnabled: () => biometricsEnabled,
        setBiometricsEnabled: (enabled) => biometricsEnabled = enabled,
        onUnlocked: (key) async {
          received = key;
          throw const FileSystemException('disco');
        },
        onLocked: () => closeCalls++,
        deviceClock: FakeDeviceClock(DateTime.now),
      );
      await session.load();

      expect(await session.unlockWithKey(testMasterKey), isFalse);
      expect(session.isLocked, isTrue);
      expect(session.isBusy, isFalse);
      expect(closeCalls, 1);
      expect(() => received!.bytes, throwsStateError);
      expect(toast.message, 'Não foi possível abrir o cofre. Tente de novo.');
    });
  });

  group('inatividade', () {
    test('bloqueia depois do tempo configurado', () {
      fakeAsync((async) {
        unlockedSession(async, (session) {
          async.elapse(const Duration(minutes: 4));
          expect(session.isLocked, isFalse);
          async.elapse(const Duration(minutes: 2));
          expect(session.isLocked, isTrue);
        });
      });
    });

    test('"nunca" desliga o bloqueio automático', () {
      fakeAsync((async) {
        autoLockMinutes = 0;
        unlockedSession(async, (session) {
          async.elapse(const Duration(hours: 2));
          expect(session.isLocked, isFalse);
        });
      });
    });
  });

  group('segundo plano', () {
    test('voltar dentro do prazo mantém o cofre aberto', () {
      fakeAsync((async) {
        unlockedSession(async, (session) {
          session.didChangeAppLifecycleState(AppLifecycleState.hidden);
          session.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(const Duration(seconds: 20));
          session.didChangeAppLifecycleState(AppLifecycleState.resumed);
          expect(session.isLocked, isFalse);

          // O prazo recomeça a cada saída.
          session.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(const Duration(seconds: 20));
          session.didChangeAppLifecycleState(AppLifecycleState.resumed);
          expect(session.isLocked, isFalse);
        });
      });
    });

    test('bloqueia depois do prazo fora do app, mesmo com inatividade em "nunca"', () {
      fakeAsync((async) {
        autoLockMinutes = 0;
        unlockedSession(async, (session) {
          session.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(AppConfig.backgroundLockDelay + AppConfig.idleCheckInterval);
          expect(session.isLocked, isTrue);
          expect(toast.message, 'Bloqueado ao sair do app');
          expect(closeCalls, 1);
        });
      });
    });

    test('ação fora do app (seletor de arquivos) não bloqueia', () {
      fakeAsync((async) {
        final suspension = LockSuspension();
        unlockedSession(lockSuspension: suspension, async, (session) {
          final picking = Completer<void>();
          suspension.during(() => picking.future);
          session.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(const Duration(minutes: 2));
          picking.complete();
          async.flushMicrotasks();
          session.didChangeAppLifecycleState(AppLifecycleState.resumed);
          expect(session.isLocked, isFalse);
          expect(suspension.isActive, isFalse);
        });
      });
    });
  });
}
