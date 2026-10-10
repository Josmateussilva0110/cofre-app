import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazenamento chave/valor persistente.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Implementação criptografada pelo Keystore (Android) / Keychain (iOS).
/// Nunca troque por SharedPreferences ou arquivo: os dados do cofre ficariam em texto puro.
class SecureKeyValueStore implements KeyValueStore {
  const SecureKeyValueStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
