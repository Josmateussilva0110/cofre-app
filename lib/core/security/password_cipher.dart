import 'dart:convert';
import 'dart:math';

import 'key_derivation.dart';
import 'memory_wipe.dart';
import 'symmetric_cipher.dart';

export 'symmetric_cipher.dart' show DecryptionFailure;

/// Texto cifrado com uma chave derivada de senha, com tudo que é preciso para decifrar (exceto a senha).
class EncryptedPayload {
  const EncryptedPayload({
    required this.iterations,
    required this.salt,
    required this.nonce,
    required this.mac,
    required this.cipherText,
  });

  final int iterations;
  final List<int> salt, nonce, mac, cipherText;
}

/// Cifra textos com AES-256-GCM usando uma chave derivada da senha ([KeyDerivation]).
class PasswordCipher {
  PasswordCipher({this.keyDerivation = const KeyDerivation(), this._random});

  static const kdfName = KeyDerivation.algorithm;
  static const cipherName = SymmetricCipher.name;

  final KeyDerivation keyDerivation;
  final Random? _random;
  final _cipher = SymmetricCipher();

  Future<EncryptedPayload> encrypt(String plainText, String password) async {
    final salt = KeyDerivation.newSalt(_random);
    final key = await keyDerivation.derive(password, salt);
    final plain = utf8.encode(plainText);
    final SealedBox box;
    try {
      box = await _cipher.seal(plain, key);
    } finally {
      wipeBytes(key);
      wipeBytes(plain);
    }
    return EncryptedPayload(
      iterations: keyDerivation.iterations,
      salt: salt,
      nonce: box.nonce,
      mac: box.mac,
      cipherText: box.cipherText,
    );
  }

  /// Lança [DecryptionFailure] se a senha estiver errada ou os dados tiverem sido alterados.
  Future<String> decrypt(EncryptedPayload payload, String password) async {
    if (!keyDerivation.accepts(payload.iterations)) throw const DecryptionFailure();
    final key = await keyDerivation.derive(password, payload.salt, iterationsOverride: payload.iterations);
    final List<int> bytes;
    try {
      bytes = await _cipher.open(
        SealedBox(nonce: payload.nonce, mac: payload.mac, cipherText: payload.cipherText),
        key,
      );
    } finally {
      wipeBytes(key);
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const DecryptionFailure();
    } finally {
      wipeBytes(bytes);
    }
  }
}
