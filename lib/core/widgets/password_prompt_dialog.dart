import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/app_strings.dart';
import '../theme/app_decorations.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'app_icon_button.dart';
import 'bare_field.dart';
import 'dialog_frame.dart';
import 'overlay_route.dart';

/// Conteúdo do diálogo que pede uma senha.
class PasswordPromptData {
  const PasswordPromptData({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.requireConfirmation = false,
    this.minLength = 1,
    this.initialError,
  });

  final String title, message, confirmLabel;

  /// Pede a senha duas vezes (ao criar uma senha nova).
  final bool requireConfirmation;
  final int minLength;

  /// Erro já exibido ao abrir (ex.: "senha incorreta" ao tentar de novo).
  final String? initialError;
}

/// Diálogo que pede uma senha. Use [PasswordPromptDialog.show], que retorna a senha ou null se cancelado.
class PasswordPromptDialog extends StatefulWidget {
  const PasswordPromptDialog({super.key, required this.data});

  final PasswordPromptData data;

  static Future<String?> show(BuildContext context, PasswordPromptData data) =>
      pushOverlay<String>(context, (_) => PasswordPromptDialog(data: data));

  @override
  State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<PasswordPromptDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late String? _error = widget.data.initialError;
  bool _isVisible = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _submit() {
    final data = widget.data;
    final password = _password.text;
    final error = password.length < data.minLength
        ? AppStrings.passwordTooShort(data.minLength)
        : data.requireConfirmation && _confirmation.text != password
        ? AppStrings.passwordsDoNotMatch
        : null;
    if (error != null) return setState(() => _error = error);
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final data = widget.data;

    return DialogFrame(
      onDismiss: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogIcon(icon: Symbols.lock_rounded, color: colors.accent, background: colors.accentSoft),
          const SizedBox(height: AppSpacing.s14),
          Text(data.title, textAlign: TextAlign.center, style: styles.titleSmall),
          const SizedBox(height: AppSpacing.s10),
          Text(
            data.message,
            textAlign: TextAlign.center,
            style: styles.paragraph.copyWith(color: colors.muted),
          ),
          const SizedBox(height: AppSpacing.s14),
          _PasswordBox(
            controller: _password,
            hint: AppStrings.backupPasswordHint,
            isVisible: _isVisible,
            hasError: _error != null,
            autofocus: true,
            onChanged: (_) => _clearError(),
            onSubmitted: data.requireConfirmation ? null : (_) => _submit(),
            onToggleVisibility: () => setState(() => _isVisible = !_isVisible),
          ),
          if (data.requireConfirmation) ...[
            const SizedBox(height: AppSpacing.s10),
            _PasswordBox(
              controller: _confirmation,
              hint: AppStrings.backupPasswordRepeatHint,
              isVisible: _isVisible,
              hasError: _error != null,
              onChanged: (_) => _clearError(),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s8, AppSpacing.s4, 0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: styles.caption.copyWith(color: colors.danger),
              ),
            ),
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  label: AppStrings.cancel,
                  background: colors.surfaceHigh,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: DialogButton(
                  label: data.confirmLabel,
                  background: colors.accent,
                  foreground: colors.onAccent,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordBox extends StatelessWidget {
  const _PasswordBox({
    required this.controller,
    required this.hint,
    required this.isVisible,
    required this.hasError,
    required this.onChanged,
    this.onSubmitted,
    this.onToggleVisibility,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool isVisible, hasError, autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Só o primeiro campo mostra o botão; o estado vale para os dois.
  final VoidCallback? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: AppSizes.confirmationFieldHeight,
      padding: EdgeInsets.fromLTRB(AppSpacing.s14, 0, onToggleVisibility == null ? AppSpacing.s14 : AppSpacing.s4, 0),
      alignment: Alignment.center,
      decoration: AppDecorations.input(colors, hasError: hasError, radius: AppRadius.r14),
      child: Row(
        children: [
          Expanded(
            child: BareField(
              controller: controller,
              hint: hint,
              obscure: !isVisible,
              autofocus: autofocus,
              autocorrect: false,
              style: context.textStyles.bodyLarge,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          if (onToggleVisibility != null)
            AppIconButton(
              icon: isVisible ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
              tooltip: AppStrings.showHide,
              size: AppSizes.iconButtonSmall,
              iconSize: AppSizes.icon20,
              color: colors.muted,
              onTap: onToggleVisibility,
            ),
        ],
      ),
    );
  }
}
