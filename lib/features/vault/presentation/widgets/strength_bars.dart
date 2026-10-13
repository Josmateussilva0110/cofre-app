import 'package:flutter/widgets.dart';

import '../../../../core/security/password_strength.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/strength_presentation.dart';

/// Quatro barrinhas que acendem conforme a pontuação da senha.
class StrengthBars extends StatelessWidget {
  const StrengthBars({super.key, required this.strength});

  final PasswordStrength strength;

  static const _thresholds = [20, 45, 75, 90];
  static const _barWidth = 16.0;
  static const _barHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeColor = colors.strength(strength.level.hue);
    return Row(
      children: [
        for (final threshold in _thresholds)
          Container(
            width: _barWidth,
            height: _barHeight,
            margin: const EdgeInsets.only(right: AppSpacing.s3),
            decoration: BoxDecoration(
              color: strength.score >= threshold ? activeColor : colors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.r2),
            ),
          ),
      ],
    );
  }
}
