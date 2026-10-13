import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/bare_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/strength_meter.dart';
import '../../../../core/widgets/tap.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_input.dart';
import '../../domain/services/password_generator.dart';
import '../widgets/entry_monogram.dart';
import '../widgets/form_field_frame.dart';
import '../widgets/hue_picker.dart';

enum EntryField { title, username, password }

/// Formulário de senha, compartilhado por criação e edição.
///
/// Não sabe se está criando ou editando: a página informa [initialValue], [title], [submitLabel] e o que fazer
/// em [onSubmit].
class EntryForm extends StatefulWidget {
  EntryForm({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    required this.onCancel,
    this.initialValue,
    PasswordGenerator? passwordGenerator,
  }) : passwordGenerator = passwordGenerator ?? PasswordGenerator();

  final EntryInput? initialValue;
  final String title;
  final String submitLabel;
  final Future<void> Function(EntryInput input) onSubmit;
  final VoidCallback onCancel;
  final PasswordGenerator passwordGenerator;

  /// Campos obrigatórios. O cofre é só local, então esta é a validação definitiva; o repositório ainda normaliza
  /// tamanhos e espaços.
  static Map<EntryField, String> validate(EntryInput input) => {
    if (input.title.trim().isEmpty) EntryField.title: AppStrings.titleRequired,
    if (input.username.trim().isEmpty) EntryField.username: AppStrings.usernameRequired,
    if (input.password.isEmpty) EntryField.password: AppStrings.passwordRequired,
  };

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late final EntryInput _initial = widget.initialValue ?? const EntryInput(title: '', username: '', password: '');
  late final _title = TextEditingController(text: _initial.title);
  late final _username = TextEditingController(text: _initial.username);
  late final _password = TextEditingController(text: _initial.password);
  late final _url = TextEditingController(text: _initial.url);
  late final _notes = TextEditingController(text: _initial.notes);
  late double _hue = _initial.hue;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  Map<EntryField, String> _errors = const {};

  @override
  void dispose() {
    for (final controller in [_title, _username, _password, _url, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  EntryInput get _input => EntryInput(
    title: _title.text,
    username: _username.text,
    password: _password.text,
    url: _url.text,
    notes: _notes.text,
    hue: _hue,
  );

  void _clearError(EntryField field) {
    if (_errors.containsKey(field)) setState(() => _errors = {..._errors}..remove(field));
  }

  void _generatePassword() {
    _password.text = widget.passwordGenerator.generate();
    _clearError(EntryField.password);
    setState(() => _isPasswordVisible = true);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final input = _input;
    final errors = EntryForm.validate(input);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(input);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final padding = MediaQuery.paddingOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: colors.screenBackground),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: padding.top),
          _FormHeader(title: widget.title, onCancel: widget.onCancel, onSave: _submit),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s18,
                AppSpacing.s6,
                AppSpacing.s18,
                AppSpacing.s40 + padding.bottom + keyboardInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s2, AppSpacing.s6, AppSpacing.s2, AppSpacing.s4),
                    child: Row(
                      children: [
                        // Só o monograma escuta o título, para não reconstruir o formulário a cada letra.
                        ListenableBuilder(
                          listenable: _title,
                          builder: (context, _) => EntryMonogram(
                            initial: Entry.initialOf(_title.text),
                            hue: _hue,
                            size: AppSizes.monogramForm,
                            radius: AppRadius.r20,
                            style: styles.monogramLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s14),
                        Expanded(
                          child: HuePicker(selected: _hue, onChanged: (hue) => setState(() => _hue = hue)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FormFieldFrame(
                    label: AppStrings.titleLabel,
                    error: _errors[EntryField.title],
                    child: _TextBox(
                      controller: _title,
                      hint: AppStrings.titleHint,
                      maxLength: EntryInput.maxTitleLength,
                      hasError: _errors.containsKey(EntryField.title),
                      onChanged: (_) => _clearError(EntryField.title),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FormFieldFrame(
                    label: AppStrings.usernameLabel,
                    error: _errors[EntryField.username],
                    child: _TextBox(
                      controller: _username,
                      hint: AppStrings.usernameHint,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      maxLength: EntryInput.maxUsernameLength,
                      hasError: _errors.containsKey(EntryField.username),
                      onChanged: (_) => _clearError(EntryField.username),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FormFieldFrame(
                    label: AppStrings.passwordLabel,
                    error: _errors[EntryField.password],
                    footer: ListenableBuilder(
                      listenable: _password,
                      builder: (context, _) => StrengthMeter(password: _password.text),
                    ),
                    child: _PasswordBox(
                      controller: _password,
                      isVisible: _isPasswordVisible,
                      hasError: _errors.containsKey(EntryField.password),
                      onChanged: (_) => _clearError(EntryField.password),
                      onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      onGenerate: _generatePassword,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FormFieldFrame(
                    label: AppStrings.urlLabel,
                    isOptional: true,
                    child: _TextBox(
                      controller: _url,
                      hint: AppStrings.urlHint,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      maxLength: EntryInput.maxUrlLength,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FormFieldFrame(
                    label: AppStrings.notesLabel,
                    isOptional: true,
                    child: _NotesBox(controller: _notes),
                  ),
                  const SizedBox(height: AppSpacing.s22),
                  PrimaryButton(label: widget.submitLabel, onTap: _submit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.title, required this.onCancel, required this.onSave});

  final String title;
  final VoidCallback onCancel, onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.s14),
      child: Row(
        children: [
          Semantics(
            button: true,
            child: Tap(
              onTap: onCancel,
              child: Text(AppStrings.cancel, style: styles.bodyLargeStrong.copyWith(color: colors.muted)),
            ),
          ),
          Expanded(
            child: Text(title, textAlign: TextAlign.center, style: styles.headerTitle),
          ),
          Semantics(
            button: true,
            child: Tap(
              onTap: onSave,
              child: Text(AppStrings.save, style: styles.bodyLargeBold.copyWith(color: colors.accent)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.keyboardType,
    this.autocorrect = true,
    this.hasError = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final TextInputType? keyboardType;
  final bool autocorrect, hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: AppSizes.fieldHeight,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
    alignment: Alignment.centerLeft,
    decoration: AppDecorations.input(context.appColors, hasError: hasError),
    child: BareField(
      controller: controller,
      hint: hint,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      maxLength: maxLength,
      onChanged: onChanged,
    ),
  );
}

class _PasswordBox extends StatelessWidget {
  const _PasswordBox({
    required this.controller,
    required this.isVisible,
    required this.hasError,
    required this.onChanged,
    required this.onToggleVisibility,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final bool isVisible, hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleVisibility, onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: AppSizes.fieldHeight,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s6, 0),
      decoration: AppDecorations.input(colors, hasError: hasError),
      child: Row(
        children: [
          Expanded(
            child: BareField(
              controller: controller,
              hint: AppStrings.passwordHint,
              obscure: !isVisible,
              secret: true,
              maxLength: EntryInput.maxPasswordLength,
              style: context.textStyles.mono,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          AppIconButton(
            icon: isVisible ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
            tooltip: AppStrings.showHide,
            iconSize: AppSizes.icon21,
            color: colors.muted,
            onTap: onToggleVisibility,
          ),
          const SizedBox(width: AppSpacing.s4),
          _GenerateButton(onTap: onGenerate),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      child: Tap(
        onTap: onTap,
        child: Container(
          height: AppSizes.iconButton,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          decoration: BoxDecoration(color: colors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.r12)),
          child: Row(
            children: [
              Icon(Symbols.autorenew_rounded, size: AppSizes.icon19, color: colors.accent),
              const SizedBox(width: AppSpacing.s5),
              Text(AppStrings.generatePassword, style: context.textStyles.captionBold.copyWith(color: colors.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesBox extends StatelessWidget {
  const _NotesBox({required this.controller});

  final TextEditingController controller;

  static const _lines = 4;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
    decoration: AppDecorations.input(context.appColors),
    child: BareField(
      controller: controller,
      hint: AppStrings.notesHint,
      minLines: _lines,
      maxLines: _lines,
      maxLength: EntryInput.maxNotesLength,
      style: context.textStyles.multilineInput,
    ),
  );
}
