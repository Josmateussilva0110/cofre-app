import 'package:flutter/widgets.dart';

import '../l10n/app_strings.dart';
import '../theme/app_decorations.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'bare_field.dart';
import 'dialog_frame.dart';
import 'overlay_route.dart';

/// Conteúdo de um diálogo de confirmação de ação destrutiva.
class ConfirmDialogData {
  const ConfirmDialogData({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.confirmationWord,
    this.confirmationHint = '',
  });

  final IconData icon;
  final String title, message, confirmLabel;

  /// Quando definido, o usuário precisa digitar esta palavra para liberar a confirmação.
  final String? confirmationWord;
  final String confirmationHint;
}

/// Diálogo de confirmação. Use [ConfirmDialog.show], que retorna true se o usuário confirmou.
class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog({super.key, required this.data});

  final ConfirmDialogData data;

  static Future<bool> show(BuildContext context, ConfirmDialogData data) async {
    final confirmed = await pushOverlay<bool>(context, (_) => ConfirmDialog(data: data));
    return confirmed ?? false;
  }

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  bool get _isReady {
    final word = widget.data.confirmationWord;
    return word == null || _confirmation.text.trim().toUpperCase() == word;
  }

  void _close(bool confirmed) => Navigator.of(context).pop(confirmed);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final data = widget.data;

    return DialogFrame(
      onDismiss: () => _close(false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogIcon(icon: data.icon, color: colors.danger, background: colors.dangerSoft),
          const SizedBox(height: AppSpacing.s14),
          Text(data.title, textAlign: TextAlign.center, style: styles.titleSmall),
          const SizedBox(height: AppSpacing.s10),
          Text(
            data.message,
            textAlign: TextAlign.center,
            style: styles.paragraph.copyWith(color: colors.muted),
          ),
          if (data.confirmationWord != null) ...[
            const SizedBox(height: AppSpacing.s14),
            _ConfirmationField(
              controller: _confirmation,
              hint: data.confirmationHint,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  label: AppStrings.cancel,
                  background: colors.surfaceHigh,
                  onTap: () => _close(false),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: DialogButton(
                  label: data.confirmLabel,
                  background: colors.danger,
                  foreground: colors.onDanger,
                  isEnabled: _isReady,
                  onTap: () {
                    if (_isReady) _close(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmationField extends StatelessWidget {
  const _ConfirmationField({required this.controller, required this.hint, required this.onChanged});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: AppSizes.confirmationFieldHeight,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
    alignment: Alignment.center,
    decoration: AppDecorations.input(context.appColors, radius: AppRadius.r14),
    child: BareField(
      controller: controller,
      hint: hint,
      autofocus: true,
      autocorrect: false,
      textAlign: TextAlign.center,
      style: context.textStyles.confirmationInput,
      onChanged: onChanged,
    ),
  );
}
