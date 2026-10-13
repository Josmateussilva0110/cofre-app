import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme_context.dart';

/// Campo de texto sem decoração do Material, para ir dentro das caixas do design.
class BareField extends StatelessWidget {
  const BareField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.secret = false,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.keyboardType,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;

  /// Campo de senha, mesmo quando o texto está visível: o teclado não sugere, não corrige e não aprende o que
  /// é digitado (teclados de terceiros podem guardar ou sincronizar o que aprendem).
  final bool secret;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextAlign textAlign;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSecret = secret || obscure;
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      keyboardType: secret && !obscure ? TextInputType.visiblePassword : keyboardType,
      maxLines: obscure ? 1 : maxLines,
      minLines: obscure ? null : minLines,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textAlign: textAlign,
      autocorrect: autocorrect && !isSecret,
      enableSuggestions: !isSecret,
      enableIMEPersonalizedLearning: !isSecret,
      cursorColor: colors.accent,
      style: (style ?? context.textStyles.input).copyWith(color: colors.text),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(color: colors.hint),
      ),
    );
  }
}
