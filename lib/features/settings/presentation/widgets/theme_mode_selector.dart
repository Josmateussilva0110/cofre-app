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
import '../../domain/app_preferences.dart';

/// Escolha entre tema claro, escuro ou do sistema.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, required this.selected, required this.onChanged});

  final AppThemeMode selected;
  final ValueChanged<AppThemeMode> onChanged;

  static const _options = [
    (AppThemeMode.light, AppStrings.themeLight, Symbols.light_mode_rounded),
    (AppThemeMode.dark, AppStrings.themeDark, Symbols.dark_mode_rounded),
    (AppThemeMode.system, AppStrings.themeSystem, Symbols.contrast_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: AppDecorations.surface(context.appColors),
      child: Row(
        children: [
          for (final (index, (mode, label, icon)) in _options.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: _ThemeOption(icon: icon, label: label, isSelected: mode == selected, onTap: () => onChanged(mode)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label, required this.isSelected, required this.onTap});

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _height = 64.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = isSelected ? colors.onAccent : colors.muted;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Tap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.short,
          height: _height,
          decoration: BoxDecoration(
            color: isSelected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSizes.icon22, color: foreground),
              const SizedBox(height: AppSpacing.s5),
              Text(label, style: context.textStyles.captionStrong.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
