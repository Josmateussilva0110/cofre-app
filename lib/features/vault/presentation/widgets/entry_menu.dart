import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/appear.dart';
import '../../../../core/widgets/hairline_divider.dart';

enum EntryMenuAction { edit, copyPassword, delete }

/// Menu de contexto de uma senha (Editar · Copiar · Excluir), ancorado ao botão "mais".
/// Fecha retornando a ação escolhida, ou null se o usuário tocou fora.
class EntryMenu extends StatelessWidget {
  const EntryMenu({super.key, required this.anchor});

  final Rect anchor;

  static const double _width = 176;
  static const double _anchorGap = 8;
  static const double _edgeMargin = 8;
  static const double _bottomSafeMargin = 24;
  static const double _anchorRightOffset = 4;
  static const double _height = AppSpacing.s6 * 2 + AppSizes.menuItemHeight * 3 + AppSizes.divider + AppSpacing.s4 * 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screen = MediaQuery.sizeOf(context);
    final opensBelow = anchor.bottom + _anchorGap + _height < screen.height - _bottomSafeMargin;
    final top = opensBelow ? anchor.bottom + _anchorGap : anchor.top - _anchorGap - _height;
    final right = (screen.width - anchor.right - _anchorRightOffset).clamp(
      _edgeMargin,
      screen.width - _width - _edgeMargin,
    );

    void choose(EntryMenuAction action) => Navigator.of(context).pop(action);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => Navigator.of(context).pop()),
        ),
        Positioned(
          top: top,
          right: right,
          width: _width,
          child: Appear(
            kind: AppearKind.pop,
            duration: AppMotion.menu,
            popAlignment: opensBelow ? Alignment.topRight : Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s6),
              decoration: BoxDecoration(
                color: colors.menuBackground,
                borderRadius: BorderRadius.circular(AppRadius.r18),
                border: Border.all(color: colors.border),
                boxShadow: AppShadows.menu,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MenuItem(
                    icon: Symbols.edit_rounded,
                    label: AppStrings.edit,
                    color: colors.text,
                    onTap: () => choose(EntryMenuAction.edit),
                  ),
                  _MenuItem(
                    icon: Symbols.content_copy_rounded,
                    label: AppStrings.copyPassword,
                    color: colors.text,
                    onTap: () => choose(EntryMenuAction.copyPassword),
                  ),
                  const HairlineDivider(
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                  ),
                  _MenuItem(
                    icon: Symbols.delete_rounded,
                    label: AppStrings.delete,
                    color: colors.danger,
                    onTap: () => choose(EntryMenuAction.delete),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isPressed = false;

  void _setPressed(bool value) => setState(() => _isPressed = value);

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: Container(
        height: AppSizes.menuItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        decoration: BoxDecoration(
          color: _isPressed ? context.appColors.pressedHighlight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: AppSizes.icon20, color: widget.color),
            const SizedBox(width: AppSpacing.s10),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyStrong.copyWith(color: widget.color),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
