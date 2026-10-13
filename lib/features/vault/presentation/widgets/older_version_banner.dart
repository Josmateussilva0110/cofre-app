import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import 'notice_banner.dart';

/// Avisa que o cofre abriu numa versão anterior à última gravada.
class OlderVersionBanner extends StatelessWidget {
  const OlderVersionBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => NoticeBanner(
    icon: Symbols.history_rounded,
    title: AppStrings.olderVersionTitle,
    message: AppStrings.olderVersionMessage,
    isWarning: true,
    actions: [NoticeBannerAction(label: AppStrings.understood, onTap: onDismiss, isPrimary: true)],
  );
}
