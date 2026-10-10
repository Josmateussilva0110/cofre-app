import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/hairline_divider.dart';
import '../../../../core/widgets/icon_tile.dart';
import '../../../../core/widgets/section_label.dart';
import '../controllers/settings_controller.dart';
import '../widgets/auto_lock_selector.dart';
import '../widgets/settings_row.dart';
import '../widgets/theme_mode_selector.dart';
import '../widgets/toggle_switch.dart';

/// Tela de ajustes. As ações de backup e de apagar o cofre vêm de fora (pertencem à feature do cofre).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.entryCount,
    required this.onBack,
    required this.onExport,
    required this.onImport,
    required this.onWipe,
  });

  final SettingsController settings;
  final int entryCount;
  final VoidCallback onBack, onExport, onImport, onWipe;

  static const _rowDivider = HairlineDivider(margin: EdgeInsets.only(left: SettingsRow.dividerIndent));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final padding = MediaQuery.paddingOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: padding.top),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s14, AppSpacing.s20, AppSpacing.s18),
          child: _SettingsHeader(onBack: onBack),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSizes.navClearance + padding.bottom),
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) {
                final preferences = settings.preferences;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionLabel(AppStrings.appearanceSection),
                    const SizedBox(height: AppSpacing.s8),
                    ThemeModeSelector(selected: preferences.themeMode, onChanged: settings.setThemeMode),
                    const SizedBox(height: AppSpacing.s22),
                    const SectionLabel(AppStrings.securitySection),
                    const SizedBox(height: AppSpacing.s8),
                    _SettingsCard(
                      children: [
                        AutoLockSelector(minutes: preferences.autoLockMinutes, onChanged: settings.setAutoLockMinutes),
                        _rowDivider,
                        SettingsRow(
                          leading: IconTile(
                            icon: Symbols.fingerprint_rounded,
                            background: colors.accentSoft,
                            color: colors.accent,
                            iconSize: AppSizes.icon22,
                          ),
                          title: AppStrings.biometricsTitle,
                          subtitle: preferences.biometricsEnabled ? AppStrings.biometricsOn : AppStrings.biometricsOff,
                          onTap: settings.toggleBiometrics,
                          trailing: ToggleSwitch(value: preferences.biometricsEnabled),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s22),
                    const SectionLabel(AppStrings.backupSection),
                    const SizedBox(height: AppSpacing.s8),
                    _SettingsCard(
                      children: [
                        SettingsRow(
                          leading: IconTile(icon: Symbols.download_rounded, background: colors.surfaceHigh),
                          title: AppStrings.exportTitle,
                          subtitle: AppStrings.exportDescription(entryCount),
                          trailing: const _Chevron(),
                          onTap: onExport,
                        ),
                        _rowDivider,
                        SettingsRow(
                          leading: IconTile(icon: Symbols.upload_rounded, background: colors.surfaceHigh),
                          title: AppStrings.importTitle,
                          subtitle: AppStrings.importDescription,
                          trailing: const _Chevron(),
                          onTap: onImport,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s22),
                    SectionLabel(AppStrings.dangerSection, color: colors.danger),
                    const SizedBox(height: AppSpacing.s8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.dangerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.r22),
                        border: Border.all(color: colors.dangerBorder),
                      ),
                      child: SettingsRow(
                        leading: IconTile(
                          icon: Symbols.delete_forever_rounded,
                          background: colors.dangerSoft,
                          color: colors.danger,
                        ),
                        title: AppStrings.wipeTitle,
                        titleColor: colors.danger,
                        subtitle: AppStrings.wipeDescription,
                        onTap: onWipe,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s26),
                    Text(
                      AppStrings.versionLabel,
                      textAlign: TextAlign.center,
                      style: context.textStyles.label.copyWith(color: colors.faint),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        AppIconButton(
          icon: Symbols.arrow_back_rounded,
          tooltip: AppStrings.back,
          size: AppSizes.iconButtonLarge,
          iconSize: AppSizes.icon22,
          radius: AppRadius.r21,
          background: colors.surface,
          borderColor: colors.border,
          color: colors.text,
          onTap: onBack,
        ),
        const SizedBox(width: AppSpacing.s12),
        Text(AppStrings.settingsTitle, style: context.textStyles.headline),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: AppDecorations.surface(context.appColors),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) =>
      Icon(Symbols.chevron_right_rounded, size: AppSizes.icon20, color: context.appColors.faint);
}
