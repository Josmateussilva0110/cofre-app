import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../../../core/security/key_derivation.dart';
import '../../../core/security/key_value_store.dart';
import '../../../core/security/password_hasher.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/master_key_repository.dart';
import '../domain/unlock_attempts.dart';

/// Guarda o hash da chave mestre e as tentativas erradas no armazenamento seguro.
class SecureMasterKeyRepository implements MasterKeyRepository {
  const SecureMasterKeyRepository(this._store, this._hasher);

  final KeyValueStore _store;
  final PasswordHasher _hasher;

  static const _algorithm = 'algorithm';
  static const _iterations = 'iterations';
  static const _salt = 'salt';
  static const _hash = 'hash';
  static const _failures = 'failures';
  static const _lockedUntil = 'lockedUntil';

  @override
  Future<bool> hasKey() async => await _store.read(AppConfig.masterKeyStorageKey) != null;

  @override
  Future<void> setKey(String key) async {
    final hash = await _hasher.hash(key);
    await _store.write(
      AppConfig.masterKeyStorageKey,
      jsonEncode({
        _algorithm: KeyDerivation.algorithm,
        _iterations: hash.iterations,
        _salt: base64Encode(hash.salt),
        _hash: base64Encode(hash.hash),
      }),
    );
  }

  @override
  Future<bool> verify(String key) async {
    final stored = await _readHash();
    return stored != null && await _hasher.verify(key, stored);
  }

  @override
  Future<void> clear() async {
    await _store.delete(AppConfig.masterKeyStorageKey);
    await _store.delete(AppConfig.unlockAttemptsStorageKey);
  }

  @override
  Future<UnlockAttempts> loadAttempts() async {
    final raw = await _store.read(AppConfig.unlockAttemptsStorageKey);
    if (raw == null) return const UnlockAttempts();
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return const UnlockAttempts();
      final failures = json[_failures];
      final lockedUntil = json[_lockedUntil];
      return UnlockAttempts(
        failures: failures is int ? failures : 0,
        lockedUntil: lockedUntil is int ? DateTime.fromMillisecondsSinceEpoch(lockedUntil) : null,
      );
    } on FormatException {
      return const UnlockAttempts();
    }
  }

  @override
  Future<void> saveAttempts(UnlockAttempts attempts) => _store.write(
    AppConfig.unlockAttemptsStorageKey,
    jsonEncode({_failures: attempts.failures, _lockedUntil: attempts.lockedUntil?.millisecondsSinceEpoch}),
  );

  /// Retorna null se o verificador estiver ausente ou ilegível (nesse caso nenhuma chave confere, e o usuário
  /// precisa usar "Esqueci a chave mestre").
  Future<PasswordHash?> _readHash() async {
    final raw = await _store.read(AppConfig.masterKeyStorageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json[_algorithm] != KeyDerivation.algorithm) return null;
      return PasswordHash(
        iterations: json[_iterations] as int,
        salt: base64Decode(json[_salt] as String),
        hash: base64Decode(json[_hash] as String),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error('SecureMasterKeyRepository.readHash', error, stackTrace);
      return null;
    }
  }
}
