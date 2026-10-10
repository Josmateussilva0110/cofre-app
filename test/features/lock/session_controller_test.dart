import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/core/feedback/toast_controller.dart';
import 'package:cofre/features/lock/domain/biometric_authenticator.dart';
import 'package:cofre/features/lock/presentation/controllers/session_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late ToastController toast;
  late FakeBiometricAuthenticator authenticator;
  late InMemoryKeyValueStore store;
  var autoLockMinutes = 5;
  var biometricsEnabled = true;

  SessionController create({DateTime Function()? clock}) => SessionController(
    authenticator: authenticator,
    masterKeys: masterKeyRepository(store),
    toast: toast,
    autoLockMinutes: () => autoLockMinutes,
    biometricsEnabled: () => biometricsEnabled,
    clock: clock ?? DateTime.now,
  );

  Future<SessionController> createWithKey() async {
    await masterKeyRepository(store).setKey(testMasterKey);
    final session = create();
    await session.load();
    return session;
  }

  setUp(() {
    toast = ToastController();
    authenticator = FakeBiometricAuthenticator();
    store = InMemoryKeyValueStore();
    autoLockMinutes = 5;
    biometricsEnabled = true;
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

    test('cria a chave, desbloqueia e guarda só o hash', () async {
      final session = create();
      await session.load();
      expect(await session.createMasterKey(testMasterKey, testMasterKey), isTrue);
      expect(session.isLocked, isFalse);
      expect(session.mode, LockMode.enterKey);
      expect(store.values[AppConfig.masterKeyStorageKey], isNot(contains(testMasterKey)));
    });

    test('digital não desbloqueia antes de existir chave', () async {
      final session = create();
      await session.load();
      await session.unlockWithBiometrics();
      expect(authenticator.calls, 0);
      expect(session.isLocked, isTrue);
    });
  });

  group('chave existente', () {
    test('chave certa desbloqueia; errada mostra erro', () async {
      final session = await createWithKey();
      expect(await session.unlockWithKey('chave-errada'), isFalse);
      expect(session.keyError, MasterKeyError.wrongKey);
      expect(await session.unlockWithKey(testMasterKey), isTrue);
      expect(session.isLocked, isFalse);
    });

    test('após 5 erros bloqueia novas tentativas, inclusive com a chave certa', () {
      fakeAsync((async) {
        late SessionController session;
        masterKeyRepository(store).setKey(testMasterKey);
        async.flushMicrotasks();
        session = create(clock: () => async.getClock(DateTime(2026)).now())..load();
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
        masterKeyRepository(store).setKey(testMasterKey);
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
      expect(store.values.containsKey(AppConfig.masterKeyStorageKey), isFalse);
    });
  });

  group('digital', () {
    test('reconhecida desbloqueia', () async {
      final session = await createWithKey();
      await session.unlockWithBiometrics();
      expect(session.isLocked, isFalse);
      expect(toast.message, 'Digital reconhecida');
    });

    test('falha mostra mensagem e mantém bloqueado', () async {
      authenticator.failure = const BiometricFailure(BiometricFailureReason.notEnrolled);
      final session = await createWithKey();
      await session.unlockWithBiometrics();
      expect(session.isLocked, isTrue);
      expect(session.isScanning, isFalse);
      expect(toast.message, 'Nenhuma digital cadastrada no aparelho');
    });

    test('desativada em Ajustes não chama o leitor', () async {
      biometricsEnabled = false;
      final session = await createWithKey();
      await session.unlockWithBiometrics();
      expect(authenticator.calls, 0);
    });
  });

  group('inatividade', () {
    void unlockedSession(FakeAsync async, void Function(SessionController session) body) {
      masterKeyRepository(store).setKey(testMasterKey);
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
