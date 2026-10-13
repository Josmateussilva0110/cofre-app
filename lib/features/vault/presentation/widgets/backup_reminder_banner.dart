import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import 'notice_banner.dart';

/// Faixa no topo do cofre sugerindo exportar um backup.
class BackupReminderBanner extends StatelessWidget {
  const BackupReminderBanner({
    super.key,
    required this.hasPreviousBackup,
    required this.onExport,
    required this.onLater,
  });

  final bool hasPreviousBackup;
  final VoidCallback onExport, onLater;

  @override
  Widget build(BuildContext context) => NoticeBanner(
    icon: Symbols.backup_rounded,
    title: hasPreviousBackup ? AppStrings.backupReminderStaleTitle : AppStrings.backupReminderFirstTitle,
    message: AppStrings.backupReminderMessage,
    actions: [
      NoticeBannerAction(label: AppStrings.backupReminderLater, onTap: onLater),
      NoticeBannerAction(label: AppStrings.backupReminderAction, onTap: onExport, isPrimary: true),
    ],
  );
}
