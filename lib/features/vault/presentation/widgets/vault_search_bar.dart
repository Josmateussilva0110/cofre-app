import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/bare_field.dart';

/// Campo de busca. A busca é local (cofre no aparelho), por isso não há debounce.
class VaultSearchBar extends StatelessWidget {
  const VaultSearchBar({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: AppSizes.searchFieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      decoration: AppDecorations.surface(colors, radius: AppRadius.r18),
      child: Row(
        children: [
          Icon(Symbols.search_rounded, size: AppSizes.icon21, color: colors.muted),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: BareField(
              controller: controller,
              hint: AppStrings.searchHint,
              style: context.textStyles.bodyLarge,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
