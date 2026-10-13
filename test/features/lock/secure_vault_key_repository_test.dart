import 'dart:convert';

import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/core/security/key_derivation.dart';
import 'package:cofre/core/security/password_hasher.dart';
import 'package:cofre/core/services/device_clock.dart';
import 'package:cofre/features/lock/domain/biometric_key_store.dart';
import 'package:cofre/features/lock/domain/unlock_attempts.dart';
import 'package:cofre/features/lock/domain/vault_key_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

const _instant = DeviceInstant(bootId: 7, sinceBoot: Duration(hours: 3));

void main() {
  late InMemoryKeyValueStore store;
  late FakeBiometricKeyStore biometrics;

  setUp(() {
    store = InMemoryKeyValueStore();
    biometrics = FakeBiometricKeyStore();
  });

  test('cria a chave do cofre e só libera com a chave mestre certa', () async {
    final keys = vaultKeyRepository(store, biometrics);
    expect(await keys.setup(), KeySetup.none);

    final created = await keys.create(testMasterKey);
    expect(await keys.setup(), KeySetup.ready);
    expect((await keys.unlock(testMasterKey))!.bytes, created.bytes);
    expect(await keys.unlock('outra-chave'), isNull);
  });

  test('nem a chave mestre nem a chave do cofre ficam gravadas em texto', () async {
    final keys = vaultKeyRepository(store, biometrics);
    final created = await keys.create(testMasterKey);
    final stored = store.values[AppConfig.vaultKeyStorageKey]!;
    expect(stored, isNot(contains(testMasterKey)));
    expect(stored, isNot(contains(base64Encode(created.bytes))));
  });

  test('versão anterior: confere o hash antigo e o remove ao criar a chave do cofre', () async {
    const hasher = PasswordHasher(keyDerivation: fastKeyDerivation);
    final hash = await hasher.hash(testMasterKey);
    store.values[AppConfig.legacyMasterKeyHashStorageKey] = jsonEncode({
      'algorithm': KeyDerivation.algorithm,
      'iterations': hash.iterations,
      'salt': base64Encode(hash.salt),
      'hash': base64Encode(hash.hash),
    });
    final keys = vaultKeyRepository(store, biometrics);

    expect(await keys.setup(), KeySetup.legacyHash);
    expect(await keys.verifyLegacy('errada'), isFalse);
    expect(await keys.verifyLegacy(testMasterKey), isTrue);

    await keys.create(testMasterKey);
    expect(await keys.setup(), KeySetup.ready);
    expect(store.values.containsKey(AppConfig.legacyMasterKeyHashStorageKey), isFalse);
  });

  test('digital libera a mesma chave do cofre', () async {
    final keys = vaultKeyRepository(store, biometrics);
    final created = await keys.create(testMasterKey);
    await keys.enableBiometrics(created, testPrompt);

    expect(await keys.hasBiometricKey(), isTrue);
    expect((await keys.unlockWithBiometrics(testPrompt)).bytes, created.bytes);
  });

  test('digital invalidada pelo sistema apaga a cópia guardada', () async {
    final keys = vaultKeyRepository(store, biometrics);
    await keys.enableBiometrics(await keys.create(testMasterKey), testPrompt);
    biometrics.nextFailure = BiometricKeyFailureReason.invalidated;

    await expectLater(
      keys.unlockWithBiometrics(testPrompt),
      throwsA(isA<BiometricKeyFailure>().having((f) => f.reason, 'reason', BiometricKeyFailureReason.invalidated)),
    );
    expect(await keys.hasBiometricKey(), isFalse);
    expect(biometrics.hasHardwareKey, isFalse);
  });

  test('criar uma chave nova descarta a digital da chave anterior', () async {
    final keys = vaultKeyRepository(store, biometrics);
    await keys.enableBiometrics(await keys.create(testMasterKey), testPrompt);
    await keys.create('outra-chave-mestre');
    expect(await keys.hasBiometricKey(), isFalse);
  });

  test('bloqueio por tentativas é salvo com o relógio do aparelho', () async {
    final keys = vaultKeyRepository(store, biometrics);
    var attempts = const UnlockAttempts();
    for (var i = 0; i < UnlockAttempts.freeAttempts; i++) {
      attempts = attempts.registerFailure(_instant);
    }
    await keys.saveAttempts(attempts);
    final loaded = await keys.loadAttempts();
    expect(loaded.failures, UnlockAttempts.freeAttempts);
    expect(loaded.remainingLockout(_instant), UnlockAttempts.baseLockout);
  });

  test('bloqueio no formato antigo (data do sistema) recomeça a espera', () async {
    final until = DateTime.now().add(const Duration(seconds: 5)).millisecondsSinceEpoch;
    store.values[AppConfig.unlockAttemptsStorageKey] = jsonEncode({'failures': 6, 'lockedUntil': until});
    final loaded = (await vaultKeyRepository(store, biometrics).loadAttempts()).reanchored(_instant);
    expect(loaded.remainingLockout(_instant), const Duration(minutes: 1));

    final expired = DateTime(2020).millisecondsSinceEpoch;
    store.values[AppConfig.unlockAttemptsStorageKey] = jsonEncode({'failures': 6, 'lockedUntil': expired});
    expect((await vaultKeyRepository(store, biometrics).loadAttempts()).remainingLockout(_instant), isNull);
  });

  test('limpar remove tudo', () async {
    final keys = vaultKeyRepository(store, biometrics);
    await keys.enableBiometrics(await keys.create(testMasterKey), testPrompt);
    await keys.saveAttempts((await keys.loadAttempts()).registerFailure(_instant));
    await keys.clear();
    expect(store.values, isEmpty);
    expect(biometrics.hasHardwareKey, isFalse);
  });
}
