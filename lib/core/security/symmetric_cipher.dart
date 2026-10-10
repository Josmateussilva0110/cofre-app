import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Dados cifrados com AES-256-GCM: o nonce e a tag de autenticação vão junto.
class SealedBox {
  const SealedBox({required this.nonce, required this.mac, required this.cipherText});

  final List<int> nonce, mac, cipherText;
}

/// Chave errada ou dados adulterados (a autenticação do AES-GCM falhou).
class DecryptionFailure implements Exception {
  const DecryptionFailure();
}

/// AES-256-GCM com uma chave de 32 bytes já pronta.
class SymmetricCipher {
  SymmetricCipher();

  static const name = 'AES-256-GCM';
  static const keyLength = 32;

  final _aes = AesGcm.with256bits();

  static List<int> newKey([Random? random]) {
    final source = random ?? Random.secure();
    return List<int>.generate(keyLength, (_) => source.nextInt(256));
  }

  Future<SealedBox> seal(List<int> plain, List<int> key) async {
    final box = await _aes.encrypt(plain, secretKey: SecretKey(key), nonce: _aes.newNonce());
    return SealedBox(nonce: box.nonce, mac: box.mac.bytes, cipherText: box.cipherText);
  }

  /// Lança [DecryptionFailure] se a chave estiver errada ou os dados tiverem sido alterados.
  Future<List<int>> open(SealedBox box, List<int> key) async {
    try {
      return await _aes.decrypt(
        SecretBox(box.cipherText, nonce: box.nonce, mac: Mac(box.mac)),
        secretKey: SecretKey(key),
      );
    } on SecretBoxAuthenticationError {
      throw const DecryptionFailure();
    } on ArgumentError {
      // Nonce ou MAC com tamanho inválido.
      throw const DecryptionFailure();
    }
  }
}
