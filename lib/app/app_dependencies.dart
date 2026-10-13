import 'package:path_provider/path_provider.dart';

import '../core/feedback/toast_controller.dart';
import '../core/security/key_derivation.dart';
import '../core/security/key_value_store.dart';
import '../core/security/lock_suspension.dart';
import '../core/security/password_cipher.dart';
import '../core/services/clipboard_service.dart';
import '../core/services/device_auth_service.dart';
import '../core/services/device_clock.dart';
import '../core/services/file_transfer_service.dart';
import '../core/services/link_launcher_service.dart';
import '../core/storage/blob_store.dart';
import '../core/theme/app_fonts.dart';
import '../core/utils/app_logger.dart';
import '../features/lock/data/platform_biometric_key_store.dart';
import '../features/lock/data/secure_vault_key_repository.dart';
import '../features/lock/domain/biometric_key_store.dart';
import '../features/lock/presentation/controllers/session_controller.dart';
import '../features/settings/data/secure_preferences_repository.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';
import '../features/vault/data/backup/encrypted_backup_codec.dart';
import '../features/vault/data/repositories/encrypted_file_entry_repository.dart';
import '../features/vault/presentation/controllers/vault_controller.dart';
import '../features/vault/presentation/pages/entry_actions.dart';
import '../features/vault/presentation/pages/vault_backup_actions.dart';
import 'legacy_storage_migration.dart';

/// Monta e guarda as dependências do app. Os parâmetros opcionais permitem trocar implementações nos testes.
class AppDependencies {
  AppDependencies._({
    required this.fonts,
    required this.toast,
    required this.settings,
    required this.vault,
    required this.session,
    required this.entryActions,
    required this.backupActions,
    required this.clipboard,
  });

  static Future<AppDependencies> create({
    KeyValueStore store = const SecureKeyValueStore(),
    BlobStore? files,
    BiometricKeyStore biometricKeys = const PlatformBiometricKeyStore(),
    ClipboardService? clipboard,
    DeviceClock? deviceClock,
    DeviceAuthService deviceAuth = const DeviceAuthService(),
    KeyDerivation keyDerivation = const KeyDerivation(),
    FileTransferService? fileTransfer,
    LinkLauncherService links = const LinkLauncherService(),
    AppFonts? fonts,
  }) async {
    try {
      await LegacyStorageMigration(store).run();
    } on Object catch (error, stackTrace) {
      // Os dados antigos continuam onde estão; a migração roda de novo na próxima abertura.
      AppLogger.error('AppDependencies.legacyMigration', error, stackTrace);
    }

    final toast = ToastController();
    final settings = SettingsController(repository: SecurePreferencesRepository(store));
    final vault = VaultController(
      repository: EncryptedFileEntryRepository(
        files: files ?? FileBlobStore(getApplicationSupportDirectory),
        store: store,
      ),
      backupCodec: EncryptedBackupCodec(cipher: PasswordCipher(keyDerivation: keyDerivation)),
    );
    final clipboardService = clipboard ?? ClipboardService();
    final lockSuspension = LockSuspension();
    final session = SessionController(
      keys: SecureVaultKeyRepository(store: store, biometrics: biometricKeys, keyDerivation: keyDerivation),
      toast: toast,
      autoLockMinutes: () => settings.preferences.autoLockMinutes,
      biometricsEnabled: () => settings.preferences.biometricsEnabled,
      setBiometricsEnabled: settings.setBiometricsEnabled,
      // O cofre só existe em memória enquanto a sessão está desbloqueada.
      onUnlocked: vault.open,
      onLocked: vault.close,
      lockSuspension: lockSuspension,
      deviceClock: deviceClock,
    );

    await Future.wait([settings.load(), session.load()]);
    session.start();

    return AppDependencies._(
      fonts: fonts ?? AppFonts.google(),
      toast: toast,
      settings: settings,
      vault: vault,
      session: session,
      entryActions: EntryActions(vault: vault, toast: toast, clipboard: clipboardService, links: links),
      backupActions: VaultBackupActions(
        vault: vault,
        toast: toast,
        files: fileTransfer ?? FileTransferService(lockSuspension: lockSuspension),
        deviceAuth: deviceAuth,
      ),
      clipboard: clipboardService,
    );
  }

  final AppFonts fonts;
  final ToastController toast;
  final SettingsController settings;
  final VaultController vault;
  final SessionController session;
  final EntryActions entryActions;
  final VaultBackupActions backupActions;
  final ClipboardService clipboard;

  void dispose() {
    session.dispose();
    vault.dispose();
    settings.dispose();
    toast.dispose();
    clipboard.dispose();
  }
}
