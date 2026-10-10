import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

/// Linha de ajuste: ícone, título, descrição e ação opcional à direita.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  /// Recuo do divisor entre linhas, alinhado ao texto (após o ícone).
  static const double dividerIndent = 66;

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleColor != null
                          ? styles.bodyLargeBold.copyWith(color: titleColor)
                          : styles.bodyLargeStrong,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(subtitle, style: styles.caption.copyWith(color: context.appColors.muted)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
