import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'tap.dart';

/// Botão principal (fundo com a cor de acento). Com [isBusy], mostra um indicador e ignora toques.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.isBusy = false});

  final String label;
  final VoidCallback onTap;
  final bool isBusy;

  static const _busyOpacity = .8;
  static const _indicatorSize = 18.0;
  static const _indicatorStroke = 2.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      enabled: !isBusy,
      child: Tap(
        onTap: isBusy ? null : onTap,
        pressedScale: Tap.subtlePressedScale,
        child: AnimatedOpacity(
          opacity: isBusy ? _busyOpacity : 1,
          duration: AppMotion.short,
          child: Container(
            height: AppSizes.primaryButtonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(AppRadius.r20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBusy) ...[
                  SizedBox(
                    width: _indicatorSize,
                    height: _indicatorSize,
                    child: CircularProgressIndicator(strokeWidth: _indicatorStroke, color: colors.onAccent),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                ],
                Text(label, style: context.textStyles.button.copyWith(color: colors.onAccent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
