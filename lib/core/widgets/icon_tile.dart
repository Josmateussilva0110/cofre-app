import 'package:flutter/widgets.dart';

import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';

/// Caixa com ícone usada no início de linhas de lista.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.background,
    this.color,
    this.iconSize = AppSizes.icon21,
  });

  final IconData icon;
  final Color background;
  final Color? color;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSizes.iconTile,
    height: AppSizes.iconTile,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.r12)),
    alignment: Alignment.center,
    child: Icon(icon, size: iconSize, color: color),
  );
}
