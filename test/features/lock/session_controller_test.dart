import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/core/feedback/toast_controller.dart';
import 'package:cofre/core/security/vault_key.dart';
import 'package:cofre/features/lock/domain/biometric_key_store.dart';
import 'package:cofre/features/lock/presentation/controllers/session_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late ToastController toast;
  late FakeBiometricKeyStore biometrics;
  late InMemoryKeyValueStore store;
  late bool biometricsEnabled;
  var autoLockMinutes = 5;
  VaultKey? openedWith;
  var closeCalls = 0;

  SessionController create({DateTime Function()? clock}) => SessionController(
    keys: vaultKeyRepository(store, biometrics),
    toast: toast,
    autoLockMinutes: () => autoLockMinutes,
    biometricsEnabled: () => biometricsEnabled,
    setBiometricsEnabled: (enabled) => biometricsEnabled = enabled,
    onUnlocked: (key) async => openedWith = key,
    onLocked: () => closeCalls++,
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
      expect(await session.createMasterKey('curta', 'curta'), isFalse);
      expect(session.keyError, MasterKeyError.tooShort);
      expect(await session.createMasterKey('chave-longa', 'chave-outra'), isFalse);
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

  group('inatividade', () {
    void unlockedSession(FakeAsync async, void Function(SessionController session) body) {
      vaultKeyRepository(store, biometrics).create(testMasterKey);
      async.flushMicrotasks();
      final session = create(clock: () => async.getClock(DateTime(2026)).now())
        ..load()
        ..start();
      async.flushMicrotasks();
      session.unlockWithKey(testMasterKey);
      async.flushMicrotasks();
      body(session);
      session.dispose();
      toast.dispose();
    }

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
}
