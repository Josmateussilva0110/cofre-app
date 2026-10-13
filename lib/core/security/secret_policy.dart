/// O que um segredo que protege o cofre precisa ter.
enum SecretRequirement { minLength, uppercase, lowercase, digit, symbol }

/// Exigência mínima para segredos que protegem o cofre (chave mestre e senha do backup).
///
/// O backup pode ser atacado offline, sem limite de tentativas: além do tamanho, exige os quatro tipos de
/// caractere. Com 8 caracteres e os quatro tipos, a senha já fica "Forte" no `PasswordStrength`.
abstract final class SecretPolicy {
  static final _uppercase = RegExp(r'[A-Z]');
  static final _lowercase = RegExp(r'[a-z]');
  static final _digit = RegExp(r'\d');
  static final _symbol = RegExp(r'[^A-Za-z0-9]');

  /// Requisitos que [secret] ainda não cumpre, na ordem de [SecretRequirement]. Vazio se é aceito.
  static List<SecretRequirement> missing(String secret, {required int minLength}) => [
    for (final requirement in SecretRequirement.values)
      if (!isMet(requirement, secret, minLength: minLength)) requirement,
  ];

  static bool isMet(SecretRequirement requirement, String secret, {required int minLength}) => switch (requirement) {
    SecretRequirement.minLength => secret.length >= minLength,
    SecretRequirement.uppercase => _uppercase.hasMatch(secret),
    SecretRequirement.lowercase => _lowercase.hasMatch(secret),
    SecretRequirement.digit => _digit.hasMatch(secret),
    SecretRequirement.symbol => _symbol.hasMatch(secret),
  };
}
