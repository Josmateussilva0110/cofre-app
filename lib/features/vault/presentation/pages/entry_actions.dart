import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/feedback/toast_controller.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/clipboard_service.dart';
import '../../../../core/services/link_launcher_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/overlay_route.dart';
import '../../domain/entities/entry.dart';
import '../controllers/vault_controller.dart';
import '../widgets/entry_detail_sheet.dart';
import '../widgets/entry_menu.dart';
import 'entry_edit_page.dart';

/// Ações sobre uma senha (copiar, abrir, editar, excluir), compartilhadas pela lista, menu e detalhe.
class EntryActions {
  const EntryActions({required this.vault, required this.toast, required this.clipboard, required this.links});

  final VaultController vault;
  final ToastController toast;
  final ClipboardService clipboard;
  final LinkLauncherService links;

  Future<void> copyPassword(Entry entry) async {
    await clipboard.copy(entry.password, sensitive: true);
    toast.show(AppStrings.passwordCopied);
  }

  Future<void> copyUsername(Entry entry) async {
    await clipboard.copy(entry.username);
    toast.show(AppStrings.usernameCopied);
  }

  Future<void> openUrl(Entry entry) async {
    var opened = false;
    try {
      opened = await links.openWeb(entry.url);
    } on Object catch (error, stackTrace) {
      AppLogger.error('EntryActions.openUrl', error, stackTrace);
    }
    if (!opened) toast.show(AppStrings.openLinkFailed);
  }

  Future<void> edit(BuildContext context, Entry entry) =>
      EntryEditPage.open(context, entry: entry, vault: vault, toast: toast);

  /// Pede confirmação e exclui. Retorna true se a senha foi excluída.
  Future<bool> confirmDelete(BuildContext context, Entry entry) async {
    final confirmed = await ConfirmDialog.show(
      context,
      ConfirmDialogData(
        icon: Symbols.delete_rounded,
        title: AppStrings.deleteEntryTitle,
        message: AppStrings.deleteEntryMessage(entry.title),
        confirmLabel: AppStrings.delete,
      ),
    );
    if (!confirmed) return false;
    try {
      await vault.delete(entry.id);
    } on Object catch (error, stackTrace) {
      AppLogger.error('EntryActions.confirmDelete', error, stackTrace);
      toast.show(AppStrings.saveFailed);
      return false;
    }
    toast.show(AppStrings.entryDeleted);
    return true;
  }

  Future<void> showDetail(BuildContext context, Entry entry) => pushOverlay<void>(
    context,
    (sheetContext) => EntryDetailSheet(
      entry: entry,
      onCopyUsername: () => copyUsername(entry),
      onCopyPassword: () => copyPassword(entry),
      onOpenUrl: () => openUrl(entry),
      onEdit: () {
        Navigator.of(sheetContext).pop();
        edit(context, entry);
      },
      onDelete: () async {
        final deleted = await confirmDelete(sheetContext, entry);
        if (deleted && sheetContext.mounted) Navigator.of(sheetContext).pop();
      },
    ),
  );

  Future<void> showMenu(BuildContext context, Entry entry, Rect anchor) async {
    final action = await pushOverlay<EntryMenuAction>(context, (_) => EntryMenu(anchor: anchor));
    if (action == null || !context.mounted) return;
    switch (action) {
      case EntryMenuAction.edit:
        await edit(context, entry);
      case EntryMenuAction.copyPassword:
        await copyPassword(entry);
      case EntryMenuAction.delete:
        await confirmDelete(context, entry);
    }
  }
}
