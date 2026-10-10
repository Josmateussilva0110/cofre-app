import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../../../core/security/key_derivation.dart';
import '../../../core/security/key_value_store.dart';
import '../../../core/security/password_hasher.dart';
import '../../../core/security/symmetric_cipher.dart';
import '../../../core/security/vault_key.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/biometric_key_store.dart';
import '../domain/unlock_attempts.dart';
import '../domain/vault_key_repository.dart';

/// Guarda a chave do cofre embrulhada no armazenamento seguro:
/// - pela chave mestre: PBKDF2 (salt próprio) gera a chave que cifra a chave do cofre com AES-256-GCM;
/// - pela digital: cópia cifrada por uma chave de hardware do Keystore ([BiometricKeyStore]).
class SecureVaultKeyRepository implements VaultKeyRepository {
  SecureVaultKeyRepository({
    required this._store,
    required this._biometrics,
    this._keyDerivation = const KeyDerivation(),
  }) : _legacyHasher = PasswordHasher(keyDerivation: _keyDerivation);

  final KeyValueStore _store;
  final BiometricKeyStore _biometrics;
  final KeyDerivation _keyDerivation;
  final PasswordHasher _legacyHasher;
  final _cipher = SymmetricCipher();

  static const _version = 'version';
  static const _currentVersion = 1;
  static const _kdf = 'kdf';
  static const _algorithm = 'algorithm';
  static const _iterations = 'iterations';
  static const _salt = 'salt';
  static const _hash = 'hash';
  static const _nonce = 'nonce';
  static const _mac = 'mac';
  static const _data = 'data';
  static const _iv = 'iv';
  static const _failures = 'failures';
  static const _lockedUntil = 'lockedUntil';

  @override
  Future<KeySetup> setup() async {
    if (await _store.read(AppConfig.vaultKeyStorageKey) != null) return KeySetup.ready;
    if (await _store.read(AppConfig.legacyMasterKeyHashStorageKey) != null) return KeySetup.legacyHash;
    return KeySetup.none;
  }

  @override
  Future<VaultKey> create(String masterKey) async {
    final vaultKey = VaultKey(SymmetricCipher.newKey());
    final salt = KeyDerivation.newSalt();
    final wrappingKey = await _keyDerivation.derive(masterKey, salt);
    final box = await _cipher.seal(vaultKey.bytes, wrappingKey);
    await _store.write(
      AppConfig.vaultKeyStorageKey,
      jsonEncode({
        _version: _currentVersion,
        _kdf: {_algorithm: KeyDerivation.algorithm, _iterations: _keyDerivation.iterations, _salt: base64Encode(salt)},
        _algorithm: SymmetricCipher.name,
        _nonce: base64Encode(box.nonce),
        _mac: base64Encode(box.mac),
        _data: base64Encode(box.cipherText),
      }),
    );
    // A chave da digital antiga protegia outra chave do cofre; não serve mais.
    await disableBiometrics();
    await _store.delete(AppConfig.legacyMasterKeyHashStorageKey);
    return vaultKey;
  }

  @override
  Future<VaultKey?> unlock(String masterKey) async {
    final stored = await _readWrappedKey();
    if (stored == null) return null;
    final wrappingKey = await _keyDerivation.derive(masterKey, stored.salt, iterationsOverride: stored.iterations);
    try {
      return VaultKey(await _cipher.open(stored.box, wrappingKey));
    } on DecryptionFailure {
      return null;
    }
  }

  @override
  Future<bool> verifyLegacy(String masterKey) async {
    final hash = await _readLegacyHash();
    return hash != null && await _legacyHasher.verify(masterKey, hash);
  }

  @override
  Future<bool> hasBiometricKey() async => await _store.read(AppConfig.biometricVaultKeyStorageKey) != null;

  @override
  Future<BiometricAvailability> biometricAvailability() => _biometrics.availability();

  @override
  Future<void> enableBiometrics(VaultKey key, BiometricPromptTexts texts) async {
    final wrapped = await _biometrics.wrap(key.bytes, texts);
    await _store.write(
      AppConfig.biometricVaultKeyStorageKey,
      jsonEncode({_iv: base64Encode(wrapped.iv), _data: base64Encode(wrapped.cipherText)}),
    );
  }

  @override
  Future<VaultKey> unlockWithBiometrics(BiometricPromptTexts texts) async {
    final wrapped = await _readBiometricKey();
    if (wrapped == null) throw const BiometricKeyFailure(BiometricKeyFailureReason.missing);
    try {
      return VaultKey(await _biometrics.unwrap(wrapped, texts));
    } on BiometricKeyFailure catch (failure) {
      // Chave invalidada pelo sistema (digital nova): a cópia guardada não pode mais ser aberta.
      if (failure.reason == BiometricKeyFailureReason.invalidated) await disableBiometrics();
      rethrow;
    }
  }

  @override
  Future<void> disableBiometrics() async {
    await _store.delete(AppConfig.biometricVaultKeyStorageKey);
    await _biometrics.delete();
  }

  @override
  Future<void> clear() async {
    await disableBiometrics();
    await _store.delete(AppConfig.vaultKeyStorageKey);
    await _store.delete(AppConfig.legacyMasterKeyHashStorageKey);
    await _store.delete(AppConfig.unlockAttemptsStorageKey);
  }

  @override
  Future<UnlockAttempts> loadAttempts() async {
    final json = await _readJson(AppConfig.unlockAttemptsStorageKey);
    if (json == null) return const UnlockAttempts();
    final failures = json[_failures];
    final lockedUntil = json[_lockedUntil];
    return UnlockAttempts(
      failures: failures is int ? failures : 0,
      lockedUntil: lockedUntil is int ? DateTime.fromMillisecondsSinceEpoch(lockedUntil) : null,
    );
  }

  @override
  Future<void> saveAttempts(UnlockAttempts attempts) => _store.write(
    AppConfig.unlockAttemptsStorageKey,
    jsonEncode({_failures: attempts.failures, _lockedUntil: attempts.lockedUntil?.millisecondsSinceEpoch}),
  );

  Future<({int iterations, List<int> salt, SealedBox box})?> _readWrappedKey() async {
    final json = await _readJson(AppConfig.vaultKeyStorageKey);
    if (json == null) return null;
    try {
      final kdf = json[_kdf] as Map<String, dynamic>;
      final iterations = kdf[_iterations] as int;
      if (kdf[_algorithm] != KeyDerivation.algorithm || !KeyDerivation.isAcceptable(iterations)) return null;
      return (
        iterations: iterations,
        salt: base64Decode(kdf[_salt] as String),
        box: SealedBox(
          nonce: base64Decode(json[_nonce] as String),
          mac: base64Decode(json[_mac] as String),
          cipherText: base64Decode(json[_data] as String),
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error('SecureVaultKeyRepository.readWrappedKey', error, stackTrace);
      return null;
    }
  }

  Future<BiometricWrappedKey?> _readBiometricKey() async {
    final json = await _readJson(AppConfig.biometricVaultKeyStorageKey);
    if (json == null) return null;
    try {
      return BiometricWrappedKey(
        iv: base64Decode(json[_iv] as String),
        cipherText: base64Decode(json[_data] as String),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error('SecureVaultKeyRepository.readBiometricKey', error, stackTrace);
      return null;
    }
  }

  Future<PasswordHash?> _readLegacyHash() async {
    final json = await _readJson(AppConfig.legacyMasterKeyHashStorageKey);
    if (json == null || json[_algorithm] != KeyDerivation.algorithm) return null;
    try {
      return PasswordHash(
        iterations: json[_iterations] as int,
        salt: base64Decode(json[_salt] as String),
        hash: base64Decode(json[_hash] as String),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error('SecureVaultKeyRepository.readLegacyHash', error, stackTrace);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _readJson(String key) async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, dynamic> ? json : null;
    } on FormatException {
      return null;
    }
  }
}
