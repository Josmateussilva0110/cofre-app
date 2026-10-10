import 'package:flutter/painting.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Decorações recorrentes do design.
abstract final class AppDecorations {
  /// Caixa padrão "surface" com borda.
  static BoxDecoration surface(AppColors colors, {double radius = AppRadius.r22}) => BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: colors.border),
  );

  /// Caixa de campo de texto (com borda vermelha quando há erro).
  static BoxDecoration input(AppColors colors, {bool hasError = false, double radius = AppRadius.r16}) => BoxDecoration(
    color: colors.inputBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: hasError ? colors.danger : colors.border),
  );
}
