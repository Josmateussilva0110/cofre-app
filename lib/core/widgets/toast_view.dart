import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'appear.dart';

/// Aviso rápido no rodapé.
class ToastView extends StatelessWidget {
  const ToastView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      liveRegion: true,
      child: Appear(
        key: ValueKey(message),
        kind: AppearKind.rise,
        duration: AppMotion.toast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s18, vertical: AppSpacing.s12),
          decoration: BoxDecoration(
            color: colors.toastBackground,
            borderRadius: BorderRadius.circular(AppRadius.r22),
            boxShadow: AppShadows.toast,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.check_circle_rounded, size: AppSizes.icon19, color: colors.accent),
              const SizedBox(width: AppSpacing.s8),
              Flexible(
                child: Text(message, style: context.textStyles.bodyStrong.copyWith(color: colors.toastText)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
