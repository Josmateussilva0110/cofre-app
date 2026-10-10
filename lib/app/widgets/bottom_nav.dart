import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/tap.dart';

enum HomeTab { vault, settings }

/// Barra de navegação flutuante (cofre · nova · ajustes).
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.selected, required this.onSelect, required this.onNewEntry});

  final HomeTab selected;
  final ValueChanged<HomeTab> onSelect;

  /// Nulo quando não é possível criar senhas (ex.: cofre ilegível).
  final VoidCallback? onNewEntry;

  static const _blurSigma = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r33),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          height: AppSizes.navHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
          decoration: BoxDecoration(
            color: colors.navBackground,
            borderRadius: BorderRadius.circular(AppRadius.r33),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavTab(
                icon: Symbols.shield_lock_rounded,
                label: AppStrings.navVault,
                isSelected: selected == HomeTab.vault,
                onTap: () => onSelect(HomeTab.vault),
              ),
              _NewEntryButton(onTap: onNewEntry),
              _NavTab(
                icon: Symbols.tune_rounded,
                label: AppStrings.navSettings,
                isSelected: selected == HomeTab.settings,
                onTap: () => onSelect(HomeTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.icon, required this.label, required this.isSelected, required this.onTap});

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
          width: AppSizes.navTabWidth,
          height: AppSizes.navTabHeight,
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.r23),
          ),
          child: Icon(icon, size: AppSizes.icon24, color: isSelected ? colors.text : colors.muted),
        ),
      ),
    );
  }
}

class _NewEntryButton extends StatelessWidget {
  const _NewEntryButton({required this.onTap});

  final VoidCallback? onTap;

  static const _disabledOpacity = .4;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tap(
      onTap: onTap,
      child: Semantics(
        label: AppStrings.navNewEntry,
        button: true,
        enabled: onTap != null,
        child: Opacity(
          opacity: onTap == null ? _disabledOpacity : 1,
          child: Container(
            width: AppSizes.navActionSize,
            height: AppSizes.navActionSize,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(colors.glow),
            ),
            child: Icon(Symbols.add_rounded, size: AppSizes.icon28, color: colors.onAccent),
          ),
        ),
      ),
    );
  }
}
