import 'package:flutter/widgets.dart';

import '../theme/app_sizes.dart';
import '../theme/theme_context.dart';

/// Linha fina de separação, com recuo opcional.
class HairlineDivider extends StatelessWidget {
  const HairlineDivider({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) =>
      Container(height: AppSizes.divider, margin: margin, color: context.appColors.border);
}
