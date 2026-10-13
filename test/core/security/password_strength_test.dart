import 'package:cofre/core/security/password_strength.dart';
import 'package:cofre/features/vault/domain/services/password_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordStrength', () {
    test('senha vazia vale zero', () {
      expect(PasswordStrength.of('').score, 0);
    });

    test('segue a fórmula do protótipo', () {
      expect(PasswordStrength.of('nu8812').level, StrengthLevel.weak);
      expect(PasswordStrength.of(r'Musica$Boa77').level, StrengthLevel.strong);
      expect(PasswordStrength.of('abcdefghijklmnop').level, StrengthLevel.medium);
    });

    test('pontuação nunca passa de 100', () {
      expect(PasswordStrength.of(r'Aa1$' * 20).score, 100);
    });
  });

  group('PasswordGenerator', () {
    test('gera senhas fortes do tamanho pedido', () {
      final generator = PasswordGenerator();
      final password = generator.generate();
      expect(password, hasLength(20));
      expect(PasswordStrength.of(password).level, StrengthLevel.strong);
      expect(generator.generate(length: 8), hasLength(8));
    });
  });
}
