import 'package:flutter/painting.dart';

/// Sombras do design. São escuras nos dois temas, por isso não ficam em [AppColors].
abstract final class AppShadows {
  static const menu = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .35), blurRadius: 40, offset: Offset(0, 20))];
  static const toast = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .3), blurRadius: 30, offset: Offset(0, 12))];
  static const switchThumb = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .25), blurRadius: 6, offset: Offset(0, 2))];

  static const walletCardResting = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, .5), blurRadius: 26, spreadRadius: -8, offset: Offset(0, -8)),
    BoxShadow(color: Color.fromRGBO(0, 0, 0, .5), blurRadius: 30, spreadRadius: -18, offset: Offset(0, 18)),
  ];
  static const walletCardLifted = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, .65), blurRadius: 50, spreadRadius: -16, offset: Offset(0, 34)),
    BoxShadow(color: Color.fromRGBO(0, 0, 0, .35), blurRadius: 20, spreadRadius: -8, offset: Offset(0, 10)),
  ];
  static const walletBadge = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .2), blurRadius: 14, offset: Offset(0, 6))];
  static const walletChip = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .25), blurRadius: 4, offset: Offset(0, 2))];
  static const walletText = [Shadow(color: Color.fromRGBO(0, 0, 0, .18), blurRadius: 2, offset: Offset(0, 1))];

  /// Brilho colorido sob elementos de destaque.
  static List<BoxShadow> glow(Color color, {double blurRadius = 20, double offsetY = 8}) => [
    BoxShadow(color: color, blurRadius: blurRadius, offset: Offset(0, offsetY)),
  ];
}
