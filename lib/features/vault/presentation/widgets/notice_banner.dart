import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/tap.dart';

/// Botão de texto de uma [NoticeBanner].
class NoticeBannerAction {
  const NoticeBannerAction({required this.label, required this.onTap, this.isPrimary = false});

  final String label;
  final VoidCallback onTap;

  /// Usa a cor de destaque da faixa; os demais ficam discretos.
  final bool isPrimary;
}

/// Faixa no topo do cofre com um aviso e ações.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.isWarning = false,
  });

  final IconData icon;
  final String title, message;
  final List<NoticeBannerAction> actions;

  /// Cores de alerta em vez das de destaque.
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final accent = isWarning ? colors.danger : colors.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s14, AppSpacing.s16, AppSpacing.s6),
      decoration: BoxDecoration(
        color: isWarning ? colors.dangerSoft : colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: AppSizes.icon24, color: accent),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: styles.bodyBold),
                    const SizedBox(height: AppSpacing.s4),
                    Text(message, style: styles.caption.copyWith(color: colors.muted)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final action in actions)
                _BannerButton(
                  label: action.label,
                  color: action.isPrimary ? accent : colors.muted,
                  onTap: action.onTap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Tap(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        alignment: Alignment.center,
        child: Text(label, style: context.textStyles.bodyBold.copyWith(color: color)),
      ),
    ),
  );
}
