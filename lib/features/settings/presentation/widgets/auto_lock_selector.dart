import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/icon_tile.dart';
import '../../../../core/widgets/tap.dart';

/// Bloqueio por inatividade: descrição e opções de tempo.
class AutoLockSelector extends StatelessWidget {
  const AutoLockSelector({super.key, required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: Symbols.timer_rounded, background: colors.accentSoft, color: colors.accent),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.autoLockTitle, style: styles.bodyLargeStrong),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      minutes > 0 ? AppStrings.autoLockDescription(minutes) : AppStrings.autoLockOff,
                      style: styles.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s6,
            children: [
              for (final option in AppConfig.autoLockOptions)
                _AutoLockChip(
                  label: AppStrings.autoLockOption(option),
                  isSelected: option == minutes,
                  onTap: () => onChanged(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutoLockChip extends StatelessWidget {
  const _AutoLockChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Tap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.short,
          height: AppSizes.chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.r18),
            border: Border.all(color: isSelected ? colors.accent : colors.border),
          ),
          child: Text(
            label,
            style: context.textStyles.captionBold.copyWith(color: isSelected ? colors.accent : colors.muted),
          ),
        ),
      ),
    );
  }
}
