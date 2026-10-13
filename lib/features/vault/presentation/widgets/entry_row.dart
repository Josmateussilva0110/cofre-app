import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/security/password_strength.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../domain/entities/entry.dart';
import 'entry_monogram.dart';
import 'strength_bars.dart';

/// Linha de uma senha na lista agrupada.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.isFirst,
    required this.onOpen,
    required this.onCopy,
    required this.onMenu,
    this.showStrength = true,
  });

  final Entry entry;
  final bool isFirst, showStrength;
  final VoidCallback onOpen, onCopy;
  final ValueChanged<Rect> onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s12, AppSpacing.s10, AppSpacing.s12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isFirst ? Colors.transparent : colors.border)),
        ),
        child: Row(
          children: [
            EntryMonogram(
              initial: entry.initial,
              hue: entry.hue,
              size: AppSizes.monogramSmall,
              radius: AppRadius.r15,
              style: styles.monogramSmall,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: styles.bodyLargeBold),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.caption.copyWith(color: colors.muted),
                  ),
                  if (showStrength) ...[
                    const SizedBox(height: AppSpacing.s6),
                    StrengthBars(strength: PasswordStrength.of(entry.password)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            AppIconButton(
              icon: Symbols.content_copy_rounded,
              tooltip: AppStrings.copyPassword,
              size: AppSizes.iconButtonSmall,
              iconSize: AppSizes.icon19,
              background: colors.accentSoft,
              color: colors.accent,
              onTap: onCopy,
            ),
            const SizedBox(width: AppSpacing.s4),
            _MoreButton(onMenu: onMenu),
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onMenu});

  final ValueChanged<Rect> onMenu;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppSizes.iconButtonCompact,
    height: AppSizes.iconButtonSmall,
    child: AppIconButton(
      icon: Symbols.more_vert_rounded,
      tooltip: AppStrings.moreOptions,
      size: AppSizes.iconButtonCompact,
      iconSize: AppSizes.icon22,
      color: context.appColors.muted,
      onTap: () {
        final box = context.findRenderObject()! as RenderBox;
        onMenu(box.localToGlobal(Offset.zero) & box.size);
      },
    ),
  );
}
