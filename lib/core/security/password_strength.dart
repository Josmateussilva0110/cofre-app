import 'dart:math' as math;

enum StrengthLevel { weak, medium, strong }

/// Pontuação 0..100 de força da senha (mesma fórmula do protótipo).
class PasswordStrength {
  const PasswordStrength._(this.score);

  factory PasswordStrength.of(String password) {
    if (password.isEmpty) return const PasswordStrength._(0);
    var score = math.min(password.length, _fullLengthBonusAt) / _fullLengthBonusAt * _lengthWeight;
    if (_lowercase.hasMatch(password)) score += _lowercaseWeight;
    if (_uppercase.hasMatch(password)) score += _uppercaseWeight;
    if (_digit.hasMatch(password)) score += _digitWeight;
    if (_symbol.hasMatch(password)) score += _symbolWeight;
    return PasswordStrength._(math.min(score, maxScore).round());
  }

  static const maxScore = 100.0;
  static const mediumThreshold = 45;
  static const strongThreshold = 75;

  static const _fullLengthBonusAt = 16;
  static const _lengthWeight = 50;
  static const _lowercaseWeight = 10;
  static const _uppercaseWeight = 12;
  static const _digitWeight = 12;
  static const _symbolWeight = 16;

  static final _lowercase = RegExp(r'[a-z]');
  static final _uppercase = RegExp(r'[A-Z]');
  static final _digit = RegExp(r'\d');
  static final _symbol = RegExp(r'[^A-Za-z0-9]');

  final int score;

  StrengthLevel get level => score < mediumThreshold
      ? StrengthLevel.weak
      : score < strongThreshold
      ? StrengthLevel.medium
      : StrengthLevel.strong;

  bool get isWeak => level == StrengthLevel.weak;
}
