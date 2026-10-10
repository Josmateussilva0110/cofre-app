import 'package:flutter/widgets.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

/// Rótulo, campo e mensagem de erro de um campo do formulário.
class FormFieldFrame extends StatelessWidget {
  const FormFieldFrame({
    super.key,
    required this.label,
    required this.child,
    this.isOptional = false,
    this.error,
    this.footer,
  });

  final String label;
  final Widget child;
  final bool isOptional;
  final String? error;

  /// Conteúdo extra entre o campo e o erro (ex.: medidor de força).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label),
                if (isOptional)
                  TextSpan(
                    text: AppStrings.optionalSuffix,
                    style: TextStyle(color: colors.faint, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
            style: styles.captionStrong.copyWith(color: colors.muted),
          ),
        ),
        child,
        if (footer != null)
          Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s8, AppSpacing.s4, 0), child: footer),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s6, AppSpacing.s4, 0),
            child: Text(error!, style: styles.label.copyWith(color: colors.danger)),
          ),
      ],
    );
  }
}
