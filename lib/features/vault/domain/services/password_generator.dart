import 'dart:math' as math;

import '../../../../core/config/app_config.dart';

/// Gera senhas aleatórias com gerador criptograficamente seguro.
class PasswordGenerator {
  PasswordGenerator([math.Random? random]) : _random = random ?? math.Random.secure();

  // Sem caracteres ambíguos (l, I, O, 0, 1) para facilitar digitar a senha em outro aparelho.
  static const _alphabet = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#\$%&*?-_';

  final math.Random _random;

  String generate({int length = AppConfig.generatedPasswordLength}) =>
      List.generate(length, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join();
}
