import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/security/password_strength.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/appear.dart';
import '../../../../core/widgets/hairline_divider.dart';
import '../../../../core/widgets/icon_tile.dart';
import '../../../../core/widgets/strength_presentation.dart';
import '../../../../core/widgets/tap.dart';
import '../../domain/entities/entry.dart';
import 'entry_monogram.dart';

/// Folha inferior com os detalhes de uma senha.
class EntryDetailSheet extends StatelessWidget {
  const EntryDetailSheet({
    super.key,
    required this.entry,
    required this.onCopyUsername,
    required this.onCopyPassword,
    required this.onOpenUrl,
    required this.onEdit,
    required this.onDelete,
  });

  final Entry entry;
  final VoidCallback onCopyUsername, onCopyPassword, onOpenUrl, onEdit, onDelete;

  void _close(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Appear(
      kind: AppearKind.fade,
      duration: AppMotion.short,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _close(context),
        child: Container(
          color: colors.overlay,
          alignment: Alignment.bottomCenter,
          child: Appear(
            kind: AppearKind.slideUp,
            duration: AppMotion.sheet,
            // Absorve toques dentro da folha e fecha ao arrastar para baixo.
            child: GestureDetector(
              onTap: () {},
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > AppMotion.sheetDismissVelocity) _close(context);
              },
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  AppSpacing.s10,
                  AppSpacing.s20,
                  AppSpacing.s34 + bottomPadding,
                ),
                decoration: BoxDecoration(
                  color: colors.sheetBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r34)),
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: AppSpacing.s14),
                    _DetailHeader(entry: entry, onClose: () => _close(context)),
                    const SizedBox(height: AppSpacing.s14),
                    _DetailFields(
                      entry: entry,
                      onCopyUsername: onCopyUsername,
                      onCopyPassword: onCopyPassword,
                      onOpenUrl: onOpenUrl,
                    ),
                    const SizedBox(height: AppSpacing.s14),
                    _DetailActions(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  static const _width = 40.0;
  static const _height = 5.0;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: context.appColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
    ),
  );
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.entry, required this.onClose});

  final Entry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    return Row(
      children: [
        EntryMonogram(
          initial: entry.initial,
          hue: entry.hue,
          size: AppSizes.monogramLarge,
          radius: AppRadius.r20,
          style: styles.monogramLarge,
        ),
        const SizedBox(width: AppSpacing.s14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, style: styles.title),
              const SizedBox(height: AppSpacing.s2),
              Text(
                AppStrings.updatedLabel(entry.updatedAt, DateTime.now()),
                style: styles.caption.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        AppIconButton(
          icon: Symbols.close_rounded,
          tooltip: AppStrings.close,
          size: AppSizes.iconButtonSmall,
          radius: AppRadius.r19,
          background: colors.surfaceHigh,
          color: colors.text,
          onTap: onClose,
        ),
      ],
    );
  }
}

class _DetailFields extends StatelessWidget {
  const _DetailFields({
    required this.entry,
    required this.onCopyUsername,
    required this.onCopyPassword,
    required this.onOpenUrl,
  });

  final Entry entry;
  final VoidCallback onCopyUsername, onCopyPassword, onOpenUrl;

  static const _dividerIndent = EdgeInsets.only(left: AppSpacing.s16);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    return Container(
      decoration: AppDecorations.surface(colors),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailField(
            label: const Text(AppStrings.usernameLabel),
            value: Text(entry.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: styles.bodyLargeStrong),
            trailing: AppIconButton(
              icon: Symbols.content_copy_rounded,
              tooltip: AppStrings.copyUsername,
              iconSize: AppSizes.icon19,
              background: colors.surfaceHigh,
              color: colors.text,
              onTap: onCopyUsername,
            ),
          ),
          const HairlineDivider(margin: _dividerIndent),
          _PasswordField(password: entry.password, onCopy: onCopyPassword),
          if (entry.url.isNotEmpty) ...[
            const HairlineDivider(margin: _dividerIndent),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenUrl,
              child: _DetailField(
                label: const Text(AppStrings.urlLabel),
                value: Text(entry.url, style: styles.bodyLargeStrong.copyWith(color: colors.accent)),
                trailing: IconTile(
                  icon: Symbols.open_in_new_rounded,
                  background: colors.surfaceHigh,
                  iconSize: AppSizes.icon19,
                ),
              ),
            ),
          ],
          if (entry.notes.isNotEmpty) ...[
            const HairlineDivider(margin: _dividerIndent),
            _DetailField(
              label: const Text(AppStrings.notesLabel),
              value: Text(entry.notes, style: styles.paragraph),
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s14),
            ),
          ],
        ],
      ),
    );
  }
}

/// Senha mascarada, com botões de mostrar/ocultar e copiar. O estado "revelada" some ao fechar a folha.
class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.password, required this.onCopy});

  final String password;
  final VoidCallback onCopy;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  static const _maxMaskLength = 14;

  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final level = PasswordStrength.of(widget.password).level;
    final mask = '•' * widget.password.length.clamp(0, _maxMaskLength);

    return _DetailField(
      label: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: '${AppStrings.passwordLabel} '),
            TextSpan(
              text: '· ${level.label}',
              style: TextStyle(color: colors.strength(level.hue), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      valueSpacing: AppSpacing.s4,
      value: Text(_isRevealed ? widget.password : mask, style: styles.mono),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: _isRevealed ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
            tooltip: AppStrings.showHidePassword,
            iconSize: AppSizes.icon19,
            background: colors.surfaceHigh,
            color: colors.text,
            onTap: () => setState(() => _isRevealed = !_isRevealed),
          ),
          const SizedBox(width: AppSpacing.s8),
          AppIconButton(
            icon: Symbols.content_copy_rounded,
            tooltip: AppStrings.copyPassword,
            iconSize: AppSizes.icon19,
            background: colors.accentSoft,
            color: colors.accent,
            onTap: widget.onCopy,
          ),
        ],
      ),
      trailingSpacing: AppSpacing.s8,
    );
  }
}

/// Linha "rótulo + valor" com ação opcional à direita.
class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.trailing,
    this.valueSpacing = AppSpacing.s3,
    this.trailingSpacing = AppSpacing.s10,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s10, AppSpacing.s12),
  });

  final Widget label, value;
  final Widget? trailing;
  final double valueSpacing, trailingSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle.merge(
                style: context.textStyles.labelStrong.copyWith(color: context.appColors.muted),
                child: label,
              ),
              SizedBox(height: valueSpacing),
              value,
            ],
          ),
        ),
        if (trailing != null) ...[SizedBox(width: trailingSpacing), trailing!],
      ],
    ),
  );
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: _SheetButton(
            icon: Symbols.edit_rounded,
            label: AppStrings.edit,
            decoration: AppDecorations.surface(colors, radius: AppRadius.r18),
            onTap: onEdit,
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        Expanded(
          child: _SheetButton(
            icon: Symbols.delete_rounded,
            label: AppStrings.delete,
            color: colors.danger,
            decoration: BoxDecoration(color: colors.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.r18)),
            onTap: onDelete,
          ),
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.label,
    required this.decoration,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final BoxDecoration decoration;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Tap(
      onTap: onTap,
      child: Container(
        height: AppSizes.secondaryButtonHeight,
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.icon20, color: color),
            const SizedBox(width: AppSpacing.s8),
            Text(label, style: context.textStyles.bodyLargeBold.copyWith(color: color)),
          ],
        ),
      ),
    ),
  );
}
