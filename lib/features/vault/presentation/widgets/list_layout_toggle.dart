import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/tap.dart';
import '../controllers/vault_controller.dart';

/// Alterna entre os layouts "carteira" e "agrupada".
class ListLayoutToggle extends StatelessWidget {
  const ListLayoutToggle({super.key, required this.selected, required this.onChanged});

  final EntryListLayout selected;
  final ValueChanged<EntryListLayout> onChanged;

  static const _options = [
    (EntryListLayout.wallet, AppStrings.layoutWallet, Symbols.view_agenda_rounded),
    (EntryListLayout.grouped, AppStrings.layoutGrouped, Symbols.format_list_bulleted_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.searchFieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      decoration: AppDecorations.surface(context.appColors, radius: AppRadius.r18),
      child: Row(
        children: [
          for (final (index, (layout, label, icon)) in _options.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.s2),
            _ToggleOption(icon: icon, label: label, isSelected: layout == selected, onTap: () => onChanged(layout)),
          ],
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({required this.icon, required this.label, required this.isSelected, required this.onTap});

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tap(
      onTap: onTap,
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: AnimatedContainer(
          duration: AppMotion.short,
          width: AppSizes.iconButtonSmall,
          height: AppSizes.iconButtonSmall,
          decoration: BoxDecoration(
            color: isSelected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          child: Icon(icon, size: AppSizes.icon20, color: isSelected ? colors.onAccent : colors.muted),
        ),
      ),
    );
  }
}
