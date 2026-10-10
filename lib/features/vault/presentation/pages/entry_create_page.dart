import 'package:flutter/widgets.dart';

import '../../../../core/feedback/toast_controller.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/entry_input.dart';
import '../controllers/vault_controller.dart';
import '../forms/entry_form.dart';
import 'entry_form_route.dart';

/// Tela "Nova senha".
class EntryCreatePage extends StatelessWidget {
  const EntryCreatePage({super.key, required this.vault, required this.toast});

  final VaultController vault;
  final ToastController toast;

  static Future<void> open(BuildContext context, {required VaultController vault, required ToastController toast}) =>
      Navigator.of(context).push(entryFormRoute((_) => EntryCreatePage(vault: vault, toast: toast)));

  Future<void> _create(BuildContext context, EntryInput input) async {
    try {
      await vault.create(input);
    } on Object catch (error, stackTrace) {
      AppLogger.error('EntryCreatePage.create', error, stackTrace);
      toast.show(AppStrings.saveFailed);
      return;
    }
    toast.show(AppStrings.entryCreated);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => EntryForm(
    title: AppStrings.newEntryTitle,
    submitLabel: AppStrings.createSubmit,
    onCancel: () => Navigator.of(context).pop(),
    onSubmit: (input) => _create(context, input),
  );
}
