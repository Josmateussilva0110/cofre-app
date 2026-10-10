import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// Estilos de texto do design, expostos como [ThemeExtension] e lidos por `context.textStyles`.
///
/// Os estilos não definem cor: ela vem do `DefaultTextStyle` do tema ou é aplicada com `copyWith(color:)`.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles._({
    required this.display,
    required this.headline,
    required this.title,
    required this.titleSmall,
    required this.cardTitle,
    required this.emptyTitle,
    required this.headerTitle,
    required this.button,
    required this.input,
    required this.masterKeyInput,
    required this.confirmationInput,
    required this.multilineInput,
    required this.groupLetter,
    required this.bodyLarge,
    required this.bodyLargeStrong,
    required this.bodyLargeBold,
    required this.body,
    required this.bodyMedium,
    required this.bodyStrong,
    required this.bodyBold,
    required this.paragraph,
    required this.caption,
    required this.captionStrong,
    required this.captionBold,
    required this.label,
    required this.labelStrong,
    required this.labelBold,
    required this.overline,
    required this.monogramSmall,
    required this.monogramLarge,
    required this.mono,
    required this.monoCardDots,
    required this.monoCardLabel,
  });

  factory AppTextStyles.from(AppFonts fonts) => AppTextStyles._(
    display: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -.6),
    headline: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -.52),
    title: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -.21),
    titleSmall: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
    cardTitle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.18),
    emptyTitle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    headerTitle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    button: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    input: const TextStyle(fontSize: 16),
    masterKeyInput: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: .32),
    confirmationInput: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    multilineInput: const TextStyle(fontSize: 15, height: 1.5),
    groupLetter: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    bodyLarge: const TextStyle(fontSize: 15),
    bodyLargeStrong: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLargeBold: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    body: const TextStyle(fontSize: 14),
    bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyStrong: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyBold: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    paragraph: const TextStyle(fontSize: 14, height: 1.5),
    caption: const TextStyle(fontSize: 13),
    captionStrong: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    captionBold: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    label: const TextStyle(fontSize: 12),
    labelStrong: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelBold: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    overline: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .96),
    monogramSmall: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    monogramLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    mono: fonts.mono(const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    monoCardDots: fonts.mono(const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 2.56)),
    monoCardLabel: fonts.mono(const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
  );

  final TextStyle display, headline, title, titleSmall, cardTitle, emptyTitle, headerTitle, button;
  final TextStyle input, masterKeyInput, confirmationInput, multilineInput;
  final TextStyle groupLetter, bodyLarge, bodyLargeStrong, bodyLargeBold;
  final TextStyle body, bodyMedium, bodyStrong, bodyBold, paragraph;
  final TextStyle caption, captionStrong, captionBold;
  final TextStyle label, labelStrong, labelBold, overline;
  final TextStyle monogramSmall, monogramLarge;
  final TextStyle mono, monoCardDots, monoCardLabel;

  // Os estilos não variam entre claro e escuro, então não há interpolação.
  @override
  AppTextStyles copyWith() => this;

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) => this;
}
