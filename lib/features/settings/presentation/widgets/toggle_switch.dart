import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

/// Chave liga/desliga visual. O toque é tratado pela linha que a contém.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      toggled: value,
      child: AnimatedContainer(
        duration: AppMotion.short,
        width: AppSizes.switchWidth,
        height: AppSizes.switchHeight,
        decoration: BoxDecoration(
          color: value ? colors.accent : colors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: AnimatedAlign(
          duration: AppMotion.short,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: AppSizes.switchThumb,
            height: AppSizes.switchThumb,
            margin: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.switchThumb,
              boxShadow: AppShadows.switchThumb,
            ),
          ),
        ),
      ),
    );
  }
}
