import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/config/app_config.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_sizes.dart';
import '../core/widgets/confirm_dialog.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/vault/domain/backup_reminder.dart';
import '../features/vault/presentation/pages/entry_create_page.dart';
import '../features/vault/presentation/pages/vault_page.dart';
import '../features/vault/presentation/widgets/backup_reminder_banner.dart';
import 'app_dependencies.dart';
import 'widgets/bottom_nav.dart';

/// App desbloqueado: abas Cofre e Ajustes com a barra de navegação flutuante.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.vault;
  bool _isBiometricOfferOpen = false;

  AppDependencies get _deps => widget.dependencies;

  @override
  void initState() {
    super.initState();
    _deps.session.addListener(_onSessionChanged);
    // A oferta pode ter surgido antes desta tela montar.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onSessionChanged());
  }

  @override
  void dispose() {
    _deps.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() => unawaited(_offerBiometrics());

  /// Explica a digital antes de acionar o sensor, para o pedido do sistema não pegar o usuário de surpresa.
  Future<void> _offerBiometrics() async {
    final session = _deps.session;
    if (_isBiometricOfferOpen || !session.hasBiometricOffer || !mounted) return;
    _isBiometricOfferOpen = true;
    final accepted = await ConfirmDialog.show(
      context,
      const ConfirmDialogData(
        icon: Symbols.fingerprint_rounded,
        title: AppStrings.biometricOfferTitle,
        message: AppStrings.biometricOfferMessage,
        confirmLabel: AppStrings.biometricOfferAccept,
        cancelLabel: AppStrings.notNow,
        tone: ConfirmDialogTone.accent,
      ),
    );
    _isBiometricOfferOpen = false;
    accepted ? await session.acceptBiometricOffer() : session.declineBiometricOffer();
  }

  Future<void> _export() async {
    if (await _deps.backupActions.export(context)) _deps.settings.recordBackup(DateTime.now());
  }

  Widget? _backupReminder() {
    final preferences = _deps.settings.preferences;
    final now = DateTime.now();
    final isDue = BackupReminder.isDue(
      entryCount: _deps.vault.entries.length,
      now: now,
      lastBackupAt: preferences.lastBackupAt,
      snoozedUntil: preferences.backupReminderSnoozedUntil,
    );
    if (!isDue) return null;
    return BackupReminderBanner(
      hasPreviousBackup: preferences.lastBackupAt != null,
      onExport: _export,
      onLater: () => _deps.settings.snoozeBackupReminder(now.add(AppConfig.backupReminderSnooze)),
    );
  }

  void _selectTab(HomeTab tab) => setState(() => _tab = tab);

  void _lock() => _deps.session.lock(message: AppStrings.vaultLocked);

  Future<void> _wipe() async {
    final wiped = await _deps.backupActions.confirmWipe(context);
    // Apagar o cofre também remove a chave mestre: o próximo acesso começa do zero.
    if (wiped) await _deps.session.resetMasterKey(message: AppStrings.vaultWiped);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // Em Ajustes, "voltar" retorna ao Cofre; no Cofre, fecha o app.
    return PopScope(
      canPop: _tab == HomeTab.vault,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(HomeTab.vault);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: Curves.easeOut,
              child: switch (_tab) {
                HomeTab.vault => ListenableBuilder(
                  key: const ValueKey(HomeTab.vault),
                  listenable: Listenable.merge([_deps.vault, _deps.settings]),
                  builder: (context, _) => VaultPage(
                    vault: _deps.vault,
                    actions: _deps.entryActions,
                    onLock: _lock,
                    notice: _backupReminder(),
                  ),
                ),
                HomeTab.settings => ListenableBuilder(
                  key: const ValueKey(HomeTab.settings),
                  listenable: _deps.vault,
                  builder: (context, _) => SettingsPage(
                    settings: _deps.settings,
                    entryCount: _deps.vault.entries.length,
                    onBack: () => _selectTab(HomeTab.vault),
                    onToggleBiometrics: () =>
                        _deps.session.setBiometrics(enabled: !_deps.settings.preferences.biometricsEnabled),
                    onExport: _export,
                    onImport: () => _deps.backupActions.import(context),
                    onWipe: _wipe,
                  ),
                ),
              },
            ),
          ),
          Positioned(
            left: AppSizes.navHorizontalInset,
            right: AppSizes.navHorizontalInset,
            bottom: AppSizes.navBottomInset + bottomPadding,
            child: ListenableBuilder(
              listenable: _deps.vault,
              builder: (context, _) => BottomNav(
                selected: _tab,
                onSelect: _selectTab,
                onNewEntry: _deps.vault.isWritable
                    ? () => EntryCreatePage.open(context, vault: _deps.vault, toast: _deps.toast)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
