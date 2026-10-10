import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'key_derivation.dart';

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

/// Senha errada ou dados adulterados (a autenticação do AES-GCM falhou).
class DecryptionFailure implements Exception {
  const DecryptionFailure();
}

/// Cifra textos com AES-256-GCM usando uma chave derivada da senha ([KeyDerivation]).
class PasswordCipher {
  PasswordCipher({this.keyDerivation = const KeyDerivation(), this._random});

  static const kdfName = KeyDerivation.algorithm;
  static const cipherName = 'AES-256-GCM';

  final KeyDerivation keyDerivation;
  final Random? _random;
  final _aes = AesGcm.with256bits();

  Future<EncryptedPayload> encrypt(String plainText, String password) async {
    final salt = KeyDerivation.newSalt(_random);
    final key = await keyDerivation.derive(password, salt);
    final box = await _aes.encrypt(utf8.encode(plainText), secretKey: SecretKey(key), nonce: _aes.newNonce());
    return EncryptedPayload(
      iterations: keyDerivation.iterations,
      salt: salt,
      nonce: box.nonce,
      mac: box.mac.bytes,
      cipherText: box.cipherText,
    );
  }

  /// Lança [DecryptionFailure] se a senha estiver errada ou os dados tiverem sido alterados.
  Future<String> decrypt(EncryptedPayload payload, String password) async {
    if (!KeyDerivation.isAcceptable(payload.iterations)) throw const DecryptionFailure();
    final key = await keyDerivation.derive(password, payload.salt, iterationsOverride: payload.iterations);
    try {
      final bytes = await _aes.decrypt(
        SecretBox(payload.cipherText, nonce: payload.nonce, mac: Mac(payload.mac)),
        secretKey: SecretKey(key),
      );
      return utf8.decode(bytes);
    } on SecretBoxAuthenticationError {
      throw const DecryptionFailure();
    } on FormatException {
      throw const DecryptionFailure();
    } on ArgumentError {
      // Nonce ou MAC com tamanho inválido.
      throw const DecryptionFailure();
    }
  }
}
