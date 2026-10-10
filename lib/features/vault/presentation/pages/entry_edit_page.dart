import 'package:flutter/widgets.dart';

import '../../../../core/feedback/toast_controller.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_input.dart';
import '../controllers/vault_controller.dart';
import '../forms/entry_form.dart';
import 'entry_form_route.dart';

/// Tela "Editar senha".
class EntryEditPage extends StatelessWidget {
  const EntryEditPage({super.key, required this.entry, required this.vault, required this.toast});

  final Entry entry;
  final VaultController vault;
  final ToastController toast;

  static Future<void> open(
    BuildContext context, {
    required Entry entry,
    required VaultController vault,
    required ToastController toast,
  }) => Navigator.of(context).push(entryFormRoute((_) => EntryEditPage(entry: entry, vault: vault, toast: toast)));

  Future<void> _update(BuildContext context, EntryInput input) async {
    try {
      await vault.update(entry.id, input);
    } on Object catch (error, stackTrace) {
      AppLogger.error('EntryEditPage.update', error, stackTrace);
      toast.show(AppStrings.saveFailed);
      return;
    }
    toast.show(AppStrings.entryUpdated);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => EntryForm(
    initialValue: EntryInput.fromEntry(entry),
    title: AppStrings.editEntryTitle,
    submitLabel: AppStrings.editSubmit,
    onCancel: () => Navigator.of(context).pop(),
    onSubmit: (input) => _update(context, input),
  );
}
