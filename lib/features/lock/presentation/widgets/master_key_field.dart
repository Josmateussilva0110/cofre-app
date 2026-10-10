import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/bare_field.dart';

/// Campo da chave mestre com botão de mostrar/ocultar.
class MasterKeyField extends StatefulWidget {
  const MasterKeyField({
    super.key,
    required this.controller,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
    this.hint = AppStrings.masterKeyHint,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool hasError, autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<MasterKeyField> createState() => _MasterKeyFieldState();
}

class _MasterKeyFieldState extends State<MasterKeyField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: AppSizes.masterKeyFieldHeight,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s18, 0, AppSpacing.s8, 0),
      decoration: AppDecorations.input(colors, hasError: widget.hasError, radius: AppRadius.r20),
      child: Row(
        children: [
          Icon(Symbols.key_rounded, size: AppSizes.icon22, color: colors.muted),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: BareField(
              controller: widget.controller,
              hint: widget.hint,
              obscure: !_isVisible,
              autofocus: widget.autofocus,
              style: context.textStyles.masterKeyInput,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
          AppIconButton(
            icon: _isVisible ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
            tooltip: AppStrings.showHide,
            size: AppSizes.iconButtonLarge,
            iconSize: AppSizes.icon22,
            radius: AppRadius.r14,
            color: colors.muted,
            onTap: () => setState(() => _isVisible = !_isVisible),
          ),
        ],
      ),
    );
  }
}
