import 'package:cofre/core/security/password_strength.dart';
import 'package:cofre/core/security/secret_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<SecretRequirement> missing(String secret) => SecretPolicy.missing(secret, minLength: 8);

  test('aponta cada requisito que falta', () {
    expect(missing(''), SecretRequirement.values);
    expect(missing('senha123'), [SecretRequirement.uppercase, SecretRequirement.symbol]);
    expect(missing('SENHA-FORTE'), [SecretRequirement.lowercase, SecretRequirement.digit]);
    expect(missing('Aa1!'), [SecretRequirement.minLength]);
  });

  test('aceita 8 caracteres com os quatro tipos', () {
    expect(missing('Aa1!aaaa'), isEmpty);
    expect(missing(r'Musica$Boa77'), isEmpty);
  });

  test('toda senha aceita já é "Forte"', () {
    for (final secret in ['Aa1!aaaa', 'Zz9-zzzz', r'Musica$Boa77']) {
      expect(missing(secret), isEmpty);
      expect(PasswordStrength.of(secret).level, StrengthLevel.strong);
    }
  });
}
