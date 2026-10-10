import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

enum VaultEmptyReason { noEntries, noResults, loadFailed }

/// Mensagem quando não há senhas para mostrar.
class VaultEmptyState extends StatelessWidget {
  const VaultEmptyState({super.key, required this.reason});

  final VaultEmptyReason reason;

  static const _iconBoxSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final (icon, title, hint) = switch (reason) {
      VaultEmptyReason.noEntries => (Symbols.lock_open_rounded, AppStrings.emptyVault, AppStrings.emptyVaultHint),
      VaultEmptyReason.noResults => (Symbols.search_off_rounded, AppStrings.nothingFound, AppStrings.nothingFoundHint),
      VaultEmptyReason.loadFailed => (Symbols.error_rounded, AppStrings.loadFailed, AppStrings.loadFailedHint),
    };
    final accent = reason == VaultEmptyReason.loadFailed ? colors.danger : colors.accent;
    final soft = reason == VaultEmptyReason.loadFailed ? colors.dangerSoft : colors.accentSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s60, horizontal: AppSpacing.s30),
      child: Column(
        children: [
          Container(
            width: _iconBoxSize,
            height: _iconBoxSize,
            decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(AppRadius.r24)),
            child: Icon(icon, size: AppSizes.icon36, color: accent),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(title, textAlign: TextAlign.center, style: styles.emptyTitle),
          const SizedBox(height: AppSpacing.s10),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: styles.paragraph.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
