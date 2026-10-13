import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/app_strings.dart';
import '../security/secret_policy.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Lista dos requisitos de [SecretPolicy], marcando o que a senha digitada já cumpre e o que ainda falta.
class SecretRequirementsList extends StatelessWidget {
  const SecretRequirementsList({super.key, required this.secret, required this.minLength});

  final String secret;
  final int minLength;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final requirement in SecretRequirement.values)
        _RequirementRow(
          label: AppStrings.secretRequirement(requirement, minLength),
          isMet: SecretPolicy.isMet(requirement, secret, minLength: minLength),
        ),
    ],
  );
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isMet ? colors.healthy : colors.muted;
    return Semantics(
      label: AppStrings.secretRequirementSemantics(label, isMet: isMet),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          children: [
            Icon(
              isMet ? Symbols.check_circle_rounded : Symbols.radio_button_unchecked_rounded,
              size: AppSizes.icon19,
              fill: isMet ? 1 : 0,
              color: color,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(label, style: context.textStyles.caption.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
