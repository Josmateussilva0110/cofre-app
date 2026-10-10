import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

/// Famílias tipográficas do design. Injetadas no tema para que os testes não acessem a rede.
class AppFonts {
  const AppFonts._({required this.sans, required this._mono});

  /// Manrope e JetBrains Mono, via google_fonts.
  factory AppFonts.google() => AppFonts._(
    sans: GoogleFonts.manrope().fontFamily,
    mono: (base) => GoogleFonts.jetBrainsMono(textStyle: base),
  );

  /// Fontes do sistema (usado nos testes).
  factory AppFonts.system() => AppFonts._(sans: null, mono: (base) => base.copyWith(fontFamily: _systemMono));

  static const _systemMono = 'monospace';

  final String? sans;
  final TextStyle Function(TextStyle base) _mono;

  TextStyle mono(TextStyle base) => _mono(base);
}
