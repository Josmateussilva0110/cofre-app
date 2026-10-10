import 'package:flutter/widgets.dart';

import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import 'tap.dart';

/// Botão quadrado/circular só com ícone. [tooltip] é obrigatório para leitores de tela.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.size = AppSizes.iconButton,
    this.iconSize = AppSizes.icon20,
    this.radius = AppRadius.r12,
    this.background,
    this.color,
    this.borderColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size, iconSize, radius;
  final Color? background, color, borderColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Tap(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            border: borderColor == null ? null : Border.all(color: borderColor!),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
