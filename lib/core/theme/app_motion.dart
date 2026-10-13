import 'package:flutter/animation.dart';

/// Durações e curvas de animação.
abstract final class AppMotion {
  static const press = Duration(milliseconds: 100);
  static const quick = Duration(milliseconds: 150);
  static const menu = Duration(milliseconds: 160);
  static const short = Duration(milliseconds: 200);
  static const toast = Duration(milliseconds: 250);
  static const medium = Duration(milliseconds: 300);
  static const sheet = Duration(milliseconds: 320);
  static const rise = Duration(milliseconds: 450);
  static const scanRing = Duration(seconds: 1);

  /// Curva "emphasized" do design (cubic-bezier(.2,.8,.2,1)).
  static const emphasized = Cubic(.2, .8, .2, 1);

  /// Velocidade mínima (px/s) do gesto para baixo que fecha uma folha inferior.
  static const sheetDismissVelocity = 300.0;
}
