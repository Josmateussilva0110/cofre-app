import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/feedback/toast_controller.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/device_auth_service.dart';
import '../../../../core/services/file_transfer_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/password_prompt_dialog.dart';
import '../../../../core/widgets/progress_overlay.dart';
import '../../domain/repositories/backup_codec.dart';
import '../controllers/vault_controller.dart';

/// Exportar, importar e apagar o cofre inteiro.
class VaultBackupActions {
  const VaultBackupActions({
    required this.vault,
    required this.toast,
    required this.files,
    this.deviceAuth = const DeviceAuthService(),
  });

  final VaultController vault;
  final ToastController toast;
  final FileTransferService files;
  final DeviceAuthService deviceAuth;

  /// Pede uma senha, criptografa o backup com ela e deixa o usuário escolher onde salvar.
  /// Retorna true se o arquivo foi salvo.
  Future<bool> export(BuildContext context) async {
    final password = await PasswordPromptDialog.show(
      context,
      const PasswordPromptData(
        title: AppStrings.exportPasswordTitle,
        message: AppStrings.exportPasswordMessage,
        confirmLabel: AppStrings.exportPasswordAction,
        requireConfirmation: true,
        minLength: AppConfig.minBackupPasswordLength,
        requireStrong: true,
      ),
    );
    if (password == null || !context.mounted) return false;

    final count = vault.entries.length;
    try {
      final content = await runWithProgress(
        context,
        AppStrings.encryptingBackup,
        () => vault.exportBackup(password: password),
      );
      final saved = await files.saveText(
        fileName: AppConfig.backupFileName,
        mimeType: AppConfig.backupMimeType,
        content: content,
      );
      if (saved) toast.show(AppStrings.exportDone(count));
      return saved;
    } on Object catch (error, stackTrace) {
      AppLogger.error('VaultBackupActions.export', error, stackTrace);
      toast.show(AppStrings.exportFailed);
      return false;
    }
  }

  /// Abre um arquivo de backup. Se for criptografado, pede a senha (e de novo, se estiver errada).
  Future<void> import(BuildContext context) async {
    final content = await _pickBackupFile();
    if (content == null) return;

    String? password;
    while (true) {
      try {
        final attempt = password;
        final int count;
        if (attempt == null) {
          count = await vault.importBackup(content);
        } else {
          if (!context.mounted) return;
          count = await runWithProgress(
            context,
            AppStrings.decryptingBackup,
            () => vault.importBackup(content, password: attempt),
          );
        }
        return toast.show(AppStrings.importDone(count));
      } on BackupFailure catch (failure) {
        if (failure.reason == BackupFailureReason.invalidFile) return toast.show(AppStrings.importInvalid);
        if (failure.reason == BackupFailureReason.tooLarge) return toast.show(AppStrings.importTooLarge);
        if (!context.mounted) return;
        password = await PasswordPromptDialog.show(
          context,
          PasswordPromptData(
            title: AppStrings.importPasswordTitle,
            message: AppStrings.importPasswordMessage,
            confirmLabel: AppStrings.importPasswordAction,
            initialError: failure.reason == BackupFailureReason.wrongPassword ? AppStrings.backupWrongPassword : null,
          ),
        );
        if (password == null || !context.mounted) return;
      } on Object catch (error, stackTrace) {
        AppLogger.error('VaultBackupActions.import', error, stackTrace);
        return toast.show(AppStrings.importInvalid);
      }
    }
  }

  /// Retorna null se o usuário cancelou ou o arquivo não pôde ser lido.
  Future<String?> _pickBackupFile() async {
    try {
      return await files.pickText();
    } on FileTooLargeFailure {
      toast.show(AppStrings.importTooLarge);
      return null;
    } on Object catch (error, stackTrace) {
      AppLogger.error('VaultBackupActions.pickBackupFile', error, stackTrace);
      toast.show(AppStrings.importInvalid);
      return null;
    }
  }

  /// Pede para digitar a palavra de confirmação e apaga tudo. Retorna true se apagou.
  /// Com [forgotMasterKey], o texto explica que apagar é o único jeito de recomeçar sem a chave e, como o cofre
  /// está bloqueado, também pede o bloqueio de tela do aparelho: quem pegar o celular não apaga tudo.
  Future<bool> confirmWipe(BuildContext context, {bool forgotMasterKey = false}) async {
    final count = vault.entries.length;
    final confirmed = await ConfirmDialog.show(
      context,
      ConfirmDialogData(
        icon: Symbols.warning_rounded,
        title: forgotMasterKey ? AppStrings.forgotKeyDialogTitle : AppStrings.wipeDialogTitle,
        message: forgotMasterKey ? AppStrings.forgotKeyDialogMessage : AppStrings.wipeDialogMessage(count),
        confirmLabel: AppStrings.wipeAction,
        confirmationWord: AppStrings.wipeConfirmationWord,
        confirmationHint: AppStrings.wipeConfirmationHint,
      ),
    );
    if (!confirmed) return false;
    if (forgotMasterKey && !await _confirmDeviceOwner()) return false;
    try {
      await vault.deleteAll();
    } on Object catch (error, stackTrace) {
      AppLogger.error('VaultBackupActions.confirmWipe', error, stackTrace);
      toast.show(AppStrings.saveFailed);
      return false;
    }
    return true;
  }

  // Sem bloqueio de tela no aparelho, a palavra de confirmação é a única barreira possível.
  Future<bool> _confirmDeviceOwner() async {
    final result = await deviceAuth.confirm(title: AppStrings.deviceAuthTitle, subtitle: AppStrings.deviceAuthSubtitle);
    if (result == DeviceAuthResult.failed) toast.show(AppStrings.wipeNotConfirmed);
    return result != DeviceAuthResult.failed;
  }
}
