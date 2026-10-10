import 'package:flutter/material.dart';

import 'oklch.dart';

/// Paleta do app, exposta como [ThemeExtension] e lida por `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Matiz do acento. O design oferece turquesa (185), índigo (275) e âmbar (70); âmbar é o padrão.
  static const double defaultAccentHue = 70;

  /// Matizes usados para indicar força de senha.
  static const double weakHue = 25;
  static const double mediumHue = 75;
  static const double strongHue = 155;

  /// Cores que o usuário pode escolher para uma senha.
  static const List<double> entryHues = [185, 150, 250, 300, 340, 25, 70];

  const AppColors({
    required this.brightness,
    required this.screenBackground,
    required this.text,
    required this.muted,
    required this.faint,
    required this.hint,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.inputBackground,
    required this.navBackground,
    required this.sheetBackground,
    required this.overlay,
    required this.menuBackground,
    required this.pressedHighlight,
    required this.danger,
    required this.onDanger,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.glow,
    required this.toastBackground,
    required this.toastText,
    required this.healthy,
    required this.switchThumb,
  });

  final Brightness brightness;
  final Gradient screenBackground;
  final Color text, muted, faint, hint;
  final Color surface, surfaceHigh, border;
  final Color inputBackground, navBackground, sheetBackground, overlay, menuBackground, pressedHighlight;
  final Color danger, onDanger, dangerSoft, dangerBorder;
  final Color accent, onAccent, accentSoft, glow;
  final Color toastBackground, toastText;
  final Color healthy, switchThumb;

  bool get isDark => brightness == Brightness.dark;

  factory AppColors.dark({double accentHue = defaultAccentHue}) => AppColors(
    brightness: Brightness.dark,
    screenBackground: _screenGradient(
      [oklch(0.37, 0.045, 225), oklch(0.21, 0.022, 238), oklch(0.145, 0.015, 245)],
      const [0, 0.48, 1],
    ),
    text: const Color(0xFFEEF2F4),
    muted: const Color.fromRGBO(230, 238, 242, 0.62),
    faint: const Color.fromRGBO(230, 238, 242, 0.38),
    hint: _hint,
    surface: const Color.fromRGBO(255, 255, 255, 0.055),
    surfaceHigh: const Color.fromRGBO(255, 255, 255, 0.1),
    border: const Color.fromRGBO(255, 255, 255, 0.08),
    inputBackground: const Color.fromRGBO(0, 0, 0, 0.22),
    navBackground: const Color.fromRGBO(30, 38, 46, 0.72),
    sheetBackground: oklch(0.21, 0.018, 240),
    overlay: const Color.fromRGBO(4, 8, 12, 0.6),
    menuBackground: oklch(0.26, 0.02, 240),
    pressedHighlight: _pressedHighlight,
    danger: oklch(0.72, 0.17, 25),
    onDanger: Colors.white,
    dangerSoft: oklch(0.72, 0.17, 25, 0.13),
    dangerBorder: oklch(0.72, 0.17, 25, 0.2),
    accent: oklch(0.82, 0.11, accentHue),
    onAccent: oklch(0.22, 0.05, accentHue),
    accentSoft: oklch(0.82, 0.11, accentHue, 0.14),
    glow: oklch(0.75, 0.12, accentHue, 0.35),
    toastBackground: const Color(0xFFF2F5F6),
    toastText: const Color(0xFF0F1A20),
    healthy: oklch(0.74, 0.15, strongHue),
    switchThumb: Colors.white,
  );

  factory AppColors.light({double accentHue = defaultAccentHue}) => AppColors(
    brightness: Brightness.light,
    screenBackground: _screenGradient(
      [oklch(0.92, 0.025, 215), oklch(0.965, 0.008, 225), oklch(0.975, 0.004, 230)],
      const [0, 0.5, 1],
    ),
    text: const Color(0xFF101A20),
    muted: const Color.fromRGBO(16, 26, 32, 0.6),
    faint: const Color.fromRGBO(16, 26, 32, 0.38),
    hint: _hint,
    surface: const Color.fromRGBO(255, 255, 255, 0.85),
    surfaceHigh: const Color.fromRGBO(16, 26, 32, 0.06),
    border: const Color.fromRGBO(16, 26, 32, 0.08),
    inputBackground: Colors.white,
    navBackground: const Color.fromRGBO(255, 255, 255, 0.8),
    sheetBackground: const Color(0xFFF6F8F9),
    overlay: const Color.fromRGBO(16, 26, 32, 0.35),
    menuBackground: Colors.white,
    pressedHighlight: _pressedHighlight,
    danger: oklch(0.56, 0.19, 25),
    onDanger: Colors.white,
    dangerSoft: oklch(0.56, 0.19, 25, 0.09),
    dangerBorder: oklch(0.56, 0.19, 25, 0.18),
    accent: oklch(0.55, 0.1, accentHue),
    onAccent: Colors.white,
    accentSoft: oklch(0.55, 0.1, accentHue, 0.11),
    glow: oklch(0.6, 0.11, accentHue, 0.3),
    toastBackground: const Color(0xFF101A20),
    toastText: const Color(0xFFEEF2F4),
    healthy: oklch(0.74, 0.15, strongHue),
    switchThumb: Colors.white,
  );

  static const _hint = Color.fromRGBO(130, 145, 155, .75);
  static const _pressedHighlight = Color.fromRGBO(127, 127, 127, .12);

  // radial-gradient(120% 55% at 50% -8%, ...): elipse quase circular num celular.
  static RadialGradient _screenGradient(List<Color> colors, List<double> stops) =>
      RadialGradient(center: const Alignment(0, -1.16), radius: 1.2, colors: colors, stops: stops);

  /// Cor de texto/barra para um matiz de força de senha.
  Color strength(double hue) => isDark ? oklch(0.74, 0.15, hue) : oklch(0.6, 0.15, hue);

  /// Versão mais brilhante, usada sobre o fundo colorido do cartão.
  Color strengthOnCard(double hue) => oklch(0.85, 0.16, hue);

  /// Monograma de uma senha (letra e fundo).
  Color monogram(double hue) => isDark ? oklch(0.8, 0.12, hue) : oklch(0.52, 0.14, hue);
  Color monogramSoft(double hue) => isDark ? oklch(0.5, 0.1, hue, 0.35) : oklch(0.9, 0.05, hue);

  /// Amostra de cor no seletor do formulário.
  Color swatch(double hue) => oklch(0.7, 0.13, hue);

  /// Fundo do cartão no layout "carteira".
  LinearGradient walletCard(double hue) => LinearGradient(
    begin: const Alignment(-1, -0.6),
    end: const Alignment(1, 0.6),
    colors: isDark
        ? [oklch(0.58, 0.12, hue), oklch(0.36, 0.09, hue + 25)]
        : [oklch(0.68, 0.13, hue), oklch(0.5, 0.12, hue + 25)],
  );

  // A paleta é sempre criada pelas fábricas `dark`/`light`; não há variações parciais.
  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      screenBackground: Gradient.lerp(screenBackground, other.screenBackground, t)!,
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      hint: c(hint, other.hint),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      border: c(border, other.border),
      inputBackground: c(inputBackground, other.inputBackground),
      navBackground: c(navBackground, other.navBackground),
      sheetBackground: c(sheetBackground, other.sheetBackground),
      overlay: c(overlay, other.overlay),
      menuBackground: c(menuBackground, other.menuBackground),
      pressedHighlight: c(pressedHighlight, other.pressedHighlight),
      danger: c(danger, other.danger),
      onDanger: c(onDanger, other.onDanger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      dangerBorder: c(dangerBorder, other.dangerBorder),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentSoft: c(accentSoft, other.accentSoft),
      glow: c(glow, other.glow),
      toastBackground: c(toastBackground, other.toastBackground),
      toastText: c(toastText, other.toastText),
      healthy: c(healthy, other.healthy),
      switchThumb: c(switchThumb, other.switchThumb),
    );
  }
}

/// Cores fixas do cartão "carteira": ficam sobre um gradiente colorido, então não mudam com o tema.
abstract final class WalletCardColors {
  static const content = Colors.white;
  static const contentShadow = Color.fromRGBO(0, 0, 0, .18);
  static const bubbleFill = Color.fromRGBO(255, 255, 255, .09);
  static const bubbleBorder = Color.fromRGBO(255, 255, 255, .16);
  static const bubbleShade = Color.fromRGBO(0, 0, 0, .12);
  static const innerBorder = Color.fromRGBO(255, 255, 255, .14);
  static const transparentWhite = Color(0x00FFFFFF);
  static const holoSoft = Color.fromRGBO(255, 255, 255, .07);
  static const holoPeak = Color.fromRGBO(255, 255, 255, .26);
  static const shine = Color.fromRGBO(255, 255, 255, .7);
  static const badgeTop = Color.fromRGBO(255, 255, 255, .34);
  static const badgeBottom = Color.fromRGBO(255, 255, 255, .1);
  static const badgeBorder = Color.fromRGBO(255, 255, 255, .3);
  static const buttonFill = Color.fromRGBO(0, 0, 0, .18);
  static const buttonBorder = Color.fromRGBO(255, 255, 255, .18);
  static const pillFill = Color.fromRGBO(0, 0, 0, .26);
  static const chipGold = [Color(0xFFF6E7B4), Color(0xFFD4B061), Color(0xFFA8843A)];
  static const chipLine = Color.fromRGBO(0, 0, 0, .22);
  static const chipBorder = Color.fromRGBO(0, 0, 0, .18);
}
