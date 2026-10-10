import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Título de seção em caixa alta.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
    child: Text(
      text.toUpperCase(),
      style: context.textStyles.overline.copyWith(color: color ?? context.appColors.muted),
    ),
  );
}
