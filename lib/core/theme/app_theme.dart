import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_text_styles.dart';

/// Monta o [ThemeData] claro/escuro a partir dos tokens.
abstract final class AppTheme {
  static const _selectionAlpha = .35;

  static ThemeData light(AppFonts fonts) => _build(AppColors.light(), fonts);
  static ThemeData dark(AppFonts fonts) => _build(AppColors.dark(), fonts);

  static ThemeData _build(AppColors colors, AppFonts fonts) {
    final base = ThemeData(
      brightness: colors.brightness,
      fontFamily: fonts.sans,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: colors.brightness,
        primary: colors.accent,
        onPrimary: colors.onAccent,
        error: colors.danger,
      ),
      scaffoldBackgroundColor: colors.sheetBackground,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: _selectionAlpha),
        selectionHandleColor: colors.accent,
      ),
      iconTheme: IconThemeData(color: colors.text),
      splashFactory: NoSplash.splashFactory,
      extensions: [colors, AppTextStyles.from(fonts)],
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: colors.text, displayColor: colors.text),
    );
  }
}
