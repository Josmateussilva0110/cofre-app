import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/theme_context.dart';

/// Quadrado com a inicial da senha, na cor escolhida para ela.
class EntryMonogram extends StatelessWidget {
  const EntryMonogram({
    super.key,
    required this.initial,
    required this.hue,
    required this.size,
    required this.radius,
    required this.style,
  });

  final String initial;
  final double hue;
  final double size, radius;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedContainer(
      duration: AppMotion.short,
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.monogramSoft(hue), borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Text(initial, style: style.copyWith(color: colors.monogram(hue))),
    );
  }
}
