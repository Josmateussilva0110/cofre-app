import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/tap.dart';

/// Amostras de cor para escolher o matiz de uma senha.
class HuePicker extends StatelessWidget {
  const HuePicker({super.key, required this.selected, required this.onChanged});

  final double selected;
  final ValueChanged<double> onChanged;

  static const _swatchSize = 26.0;
  static const _ringWidth = 5.0;
  static const _gapWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      spacing: AppSpacing.s10,
      runSpacing: AppSpacing.s10,
      children: [
        for (final hue in AppColors.entryHues)
          Semantics(
            button: true,
            selected: hue == selected,
            child: Tap(
              onTap: () => onChanged(hue),
              child: AnimatedContainer(
                duration: AppMotion.quick,
                width: _swatchSize,
                height: _swatchSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.swatch(hue),
                  boxShadow: hue == selected
                      ? [
                          BoxShadow(color: colors.swatch(hue), spreadRadius: _ringWidth),
                          BoxShadow(color: colors.sheetBackground, spreadRadius: _gapWidth),
                        ]
                      : const [],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
