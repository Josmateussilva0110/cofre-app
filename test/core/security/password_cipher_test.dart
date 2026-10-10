import 'package:cofre/core/security/key_derivation.dart';
import 'package:cofre/core/security/password_cipher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cipher = PasswordCipher(keyDerivation: const KeyDerivation(iterations: 1000, runInIsolate: false));

  test('cifra e decifra com a mesma senha', () async {
    final payload = await cipher.encrypt('segredo', 'senha-forte');
    expect(payload.cipherText, isNot(equals('segredo'.codeUnits)));
    expect(await cipher.decrypt(payload, 'senha-forte'), 'segredo');
  });

  test('salt e nonce mudam a cada cifra', () async {
    final first = await cipher.encrypt('igual', 'senha');
    final second = await cipher.encrypt('igual', 'senha');
    expect(first.salt, isNot(equals(second.salt)));
    expect(first.nonce, isNot(equals(second.nonce)));
  });

  test('senha errada falha', () async {
    final payload = await cipher.encrypt('segredo', 'certa');
    expect(cipher.decrypt(payload, 'errada'), throwsA(isA<DecryptionFailure>()));
  });

  test('conteúdo adulterado falha', () async {
    final payload = await cipher.encrypt('segredo', 'senha');
    final tampered = EncryptedPayload(
      iterations: payload.iterations,
      salt: payload.salt,
      nonce: payload.nonce,
      mac: payload.mac,
      cipherText: [...payload.cipherText]..[0] ^= 1,
    );
    expect(cipher.decrypt(tampered, 'senha'), throwsA(isA<DecryptionFailure>()));
  });

  test('recusa número de iterações fora do limite sem tentar derivar', () async {
    final payload = await cipher.encrypt('segredo', 'senha');
    final abusive = EncryptedPayload(
      iterations: KeyDerivation.maxIterations + 1,
      salt: payload.salt,
      nonce: payload.nonce,
      mac: payload.mac,
      cipherText: payload.cipherText,
    );
    expect(cipher.decrypt(abusive, 'senha'), throwsA(isA<DecryptionFailure>()));
  });

  test('deriva a chave em isolate', () async {
    final isolated = PasswordCipher(keyDerivation: const KeyDerivation(iterations: 1000));
    final payload = await isolated.encrypt('segredo', 'senha');
    expect(await isolated.decrypt(payload, 'senha'), 'segredo');
  });
}
