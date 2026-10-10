import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';

/// Topo da tela do cofre: emblema, resumo (total e fracas) e botão de bloquear.
class VaultHeader extends StatelessWidget {
  const VaultHeader({super.key, required this.totalCount, required this.weakCount, required this.onLock});

  final int totalCount;
  final int weakCount;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: AppSizes.iconButtonLarge,
          height: AppSizes.iconButtonLarge,
          decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
          child: Icon(Symbols.shield_lock_rounded, size: AppSizes.icon24, fill: 1, color: colors.onAccent),
        ),
        const SizedBox(width: AppSpacing.s8),
        Icon(Symbols.chevron_right_rounded, size: AppSizes.icon20, color: colors.faint),
        const SizedBox(width: AppSpacing.s10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _SummaryPill(totalCount: totalCount, weakCount: weakCount),
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        AppIconButton(
          icon: Symbols.lock_rounded,
          tooltip: AppStrings.lockAction,
          size: AppSizes.iconButtonLarge,
          iconSize: AppSizes.icon21,
          radius: AppRadius.r21,
          background: colors.surface,
          borderColor: colors.border,
          color: colors.text,
          onTap: onLock,
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.totalCount, required this.weakCount});

  final int totalCount;
  final int weakCount;

  static const _separatorHeight = 16.0;
  static const _dotSize = 8.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final secondary = styles.bodyMedium.copyWith(color: colors.muted);
    final hasWeak = weakCount > 0;

    return Container(
      height: AppSizes.iconButtonLarge,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r21),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$totalCount', style: styles.bodyStrong),
          const SizedBox(width: AppSpacing.s4),
          Text(AppStrings.passwordsUnit, style: secondary),
          const SizedBox(width: AppSpacing.s10),
          Container(width: AppSizes.divider, height: _separatorHeight, color: colors.border),
          const SizedBox(width: AppSpacing.s10),
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: hasWeak ? colors.danger : colors.healthy),
          ),
          const SizedBox(width: AppSpacing.s6),
          Flexible(
            child: Text(
              hasWeak ? AppStrings.weakCount(weakCount) : AppStrings.allStrong,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: secondary,
            ),
          ),
        ],
      ),
    );
  }
}
