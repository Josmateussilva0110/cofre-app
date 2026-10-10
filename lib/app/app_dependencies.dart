import '../core/feedback/toast_controller.dart';
import '../core/security/key_derivation.dart';
import '../core/security/key_value_store.dart';
import '../core/security/password_cipher.dart';
import '../core/security/password_hasher.dart';
import '../core/services/clipboard_service.dart';
import '../core/services/file_transfer_service.dart';
import '../core/services/link_launcher_service.dart';
import '../core/theme/app_fonts.dart';
import '../features/lock/data/local_auth_biometric_authenticator.dart';
import '../features/lock/data/secure_master_key_repository.dart';
import '../features/lock/domain/biometric_authenticator.dart';
import '../features/lock/presentation/controllers/session_controller.dart';
import '../features/settings/data/secure_preferences_repository.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';
import '../features/vault/data/backup/encrypted_backup_codec.dart';
import '../features/vault/data/repositories/secure_entry_repository.dart';
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
    BiometricAuthenticator? authenticator,
    ClipboardService? clipboard,
    KeyDerivation keyDerivation = const KeyDerivation(),
    FileTransferService files = const FileTransferService(),
    LinkLauncherService links = const LinkLauncherService(),
    AppFonts? fonts,
  }) async {
    await LegacyStorageMigration(store).run();

    final toast = ToastController();
    final settings = SettingsController(repository: SecurePreferencesRepository(store));
    final vault = VaultController(
      repository: SecureEntryRepository(store),
      backupCodec: EncryptedBackupCodec(cipher: PasswordCipher(keyDerivation: keyDerivation)),
    );
    final clipboardService = clipboard ?? ClipboardService();
    final session = SessionController(
      authenticator: authenticator ?? LocalAuthBiometricAuthenticator(),
      masterKeys: SecureMasterKeyRepository(store, PasswordHasher(keyDerivation: keyDerivation)),
      toast: toast,
      autoLockMinutes: () => settings.preferences.autoLockMinutes,
      biometricsEnabled: () => settings.preferences.biometricsEnabled,
    );

    await Future.wait([settings.load(), vault.load(), session.load()]);
    session.start();

    return AppDependencies._(
      fonts: fonts ?? AppFonts.google(),
      toast: toast,
      settings: settings,
      vault: vault,
      session: session,
      entryActions: EntryActions(vault: vault, toast: toast, clipboard: clipboardService, links: links),
      backupActions: VaultBackupActions(vault: vault, toast: toast, files: files),
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
