import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/tap.dart';

/// Faixa no topo do cofre sugerindo exportar um backup.
class BackupReminderBanner extends StatelessWidget {
  const BackupReminderBanner({
    super.key,
    required this.hasPreviousBackup,
    required this.onExport,
    required this.onLater,
  });

  final bool hasPreviousBackup;
  final VoidCallback onExport, onLater;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s14, AppSpacing.s16, AppSpacing.s6),
      decoration: BoxDecoration(color: colors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.r20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.backup_rounded, size: AppSizes.icon24, color: colors.accent),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPreviousBackup ? AppStrings.backupReminderStaleTitle : AppStrings.backupReminderFirstTitle,
                      style: styles.bodyBold,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(AppStrings.backupReminderMessage, style: styles.caption.copyWith(color: colors.muted)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _BannerButton(label: AppStrings.backupReminderLater, color: colors.muted, onTap: onLater),
              _BannerButton(label: AppStrings.backupReminderAction, color: colors.accent, onTap: onExport),
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
