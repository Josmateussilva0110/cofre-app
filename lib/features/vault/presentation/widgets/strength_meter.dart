import 'package:flutter/widgets.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/services/password_strength.dart';
import 'strength_presentation.dart';

/// Barra de força da senha com o rótulo ao lado (formulário).
class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.password});

  final String password;

  static const _barHeight = 6.0;
  static const _labelWidth = 44.0;

  /// Largura mínima da barra, para que uma senha muito fraca ainda apareça.
  static const _minVisibleScore = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final strength = PasswordStrength.of(password);
    final isEmpty = password.isEmpty;
    final color = isEmpty ? colors.faint : colors.strength(strength.level.hue);
    final fill = isEmpty
        ? 0.0
        : strength.score.clamp(_minVisibleScore, PasswordStrength.maxScore) / PasswordStrength.maxScore;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: _barHeight,
            decoration: BoxDecoration(color: colors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.r3)),
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: AppMotion.medium,
              widthFactor: fill,
              child: AnimatedContainer(
                duration: AppMotion.medium,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.r3)),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        SizedBox(
          width: _labelWidth,
          child: Text(
            isEmpty ? AppStrings.emptyValue : strength.level.label,
            textAlign: TextAlign.right,
            style: context.textStyles.labelBold.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
