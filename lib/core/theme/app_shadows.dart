import 'package:flutter/painting.dart';

/// Sombras do design. São escuras nos dois temas, por isso não ficam em [AppColors].
abstract final class AppShadows {
  static const menu = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .35), blurRadius: 40, offset: Offset(0, 20))];
  static const toast = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .3), blurRadius: 30, offset: Offset(0, 12))];
  static const switchThumb = [BoxShadow(color: Color.fromRGBO(0, 0, 0, .25), blurRadius: 6, offset: Offset(0, 2))];

  /// Brilho colorido sob elementos de destaque.
  static List<BoxShadow> glow(Color color, {double blurRadius = 20, double offsetY = 8}) => [
    BoxShadow(color: color, blurRadius: blurRadius, offset: Offset(0, offsetY)),
  ];
}
