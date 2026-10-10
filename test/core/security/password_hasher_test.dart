import 'package:cofre/core/security/key_derivation.dart';
import 'package:cofre/core/security/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hasher = PasswordHasher(keyDerivation: KeyDerivation(iterations: 1000, runInIsolate: false));

  test('confere a senha certa e recusa as outras', () async {
    final hash = await hasher.hash('chave-mestre');
    expect(await hasher.verify('chave-mestre', hash), isTrue);
    expect(await hasher.verify('chave-mestrE', hash), isFalse);
    expect(await hasher.verify('', hash), isFalse);
  });

  test('a mesma senha gera hashes diferentes (salt aleatório)', () async {
    final first = await hasher.hash('igual');
    final second = await hasher.hash('igual');
    expect(first.hash, isNot(equals(second.hash)));
  });

  test('parâmetros salvos fora do limite são recusados', () async {
    final hash = await hasher.hash('chave');
    final abusive = PasswordHash(iterations: KeyDerivation.maxIterations + 1, salt: hash.salt, hash: hash.hash);
    expect(await hasher.verify('chave', abusive), isFalse);
  });
}
