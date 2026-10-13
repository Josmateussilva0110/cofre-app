import 'key_derivation.dart';

/// Hash de senha com os parâmetros usados para gerá-lo.
class PasswordHash {
  const PasswordHash({required this.iterations, required this.salt, required this.hash});

  final int iterations;
  final List<int> salt, hash;
}

/// Gera e confere hashes de senha. A senha em si nunca é guardada.
class PasswordHasher {
  const PasswordHasher({this.keyDerivation = const KeyDerivation()});

  final KeyDerivation keyDerivation;

  Future<PasswordHash> hash(String password) async {
    final salt = KeyDerivation.newSalt();
    return PasswordHash(
      iterations: keyDerivation.iterations,
      salt: salt,
      hash: await keyDerivation.derive(password, salt),
    );
  }

  Future<bool> verify(String password, PasswordHash stored) async {
    if (!KeyDerivation.isWithinMax(stored.iterations)) return false;
    final candidate = await keyDerivation.derive(password, stored.salt, iterationsOverride: stored.iterations);
    return _constantTimeEquals(candidate, stored.hash);
  }

  // Compara todos os bytes mesmo após encontrar diferença, para não vazar informação pelo tempo de resposta.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
