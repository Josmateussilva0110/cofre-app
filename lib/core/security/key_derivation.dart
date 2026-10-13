import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Deriva chaves de senhas com PBKDF2-HMAC-SHA256.
///
/// É lento de propósito (centenas de ms a alguns segundos) para encarecer ataques de força bruta; por isso roda em
/// isolate e a interface não trava.
class KeyDerivation {
  const KeyDerivation({
    this.iterations = defaultIterations,
    this.minIterations = defaultMinIterations,
    this.runInIsolate = true,
  });

  /// Recomendação da OWASP (2023) para PBKDF2-HMAC-SHA256.
  static const defaultIterations = 600000;

  /// Faixa aceita ao ler parâmetros salvos ou de arquivos. O app só gera [defaultIterations]: o piso recusa
  /// arquivos fáceis de quebrar e o teto impede que um valor absurdo trave o app por minutos.
  static const defaultMinIterations = 100000;
  static const maxIterations = 2000000;

  static const algorithm = 'PBKDF2-HMAC-SHA256';
  static const _keyBits = 256;
  static const _saltLength = 16;

  final int iterations;

  /// Piso aceito em [accepts]. Só os testes usam um valor menor, para rodar rápido.
  final int minIterations;
  final bool runInIsolate;

  static List<int> newSalt([Random? random]) {
    final source = random ?? Random.secure();
    return List<int>.generate(_saltLength, (_) => source.nextInt(256));
  }

  bool accepts(int iterations) => iterations >= minIterations && iterations <= maxIterations;

  /// Só o teto: o hash da versão antiga pode ter sido feito com outros parâmetros e precisa continuar abrindo.
  static bool isWithinMax(int iterations) => iterations >= 1 && iterations <= maxIterations;

  /// Deriva a chave com [iterationsOverride] (parâmetro lido de dados salvos) ou com o padrão desta instância.
  Future<List<int>> derive(String password, List<int> salt, {int? iterationsOverride}) {
    final rounds = iterationsOverride ?? iterations;
    return runInIsolate ? Isolate.run(() => _derive(password, salt, rounds)) : _derive(password, salt, rounds);
  }

  // Estático para o isolate não capturar a instância.
  static Future<List<int>> _derive(String password, List<int> salt, int iterations) async {
    final kdf = DartPbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _keyBits,
      // Sem pausas: roda em isolate, então não precisa ceder a vez à interface.
      pauseFrequency: iterations + 1,
    );
    final key = await kdf.deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }
}
