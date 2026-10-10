import 'package:flutter/widgets.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_sizes.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/vault/presentation/pages/entry_create_page.dart';
import '../features/vault/presentation/pages/vault_page.dart';
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

  AppDependencies get _deps => widget.dependencies;

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
                HomeTab.vault => VaultPage(
                  key: const ValueKey(HomeTab.vault),
                  vault: _deps.vault,
                  actions: _deps.entryActions,
                  onLock: _lock,
                ),
                HomeTab.settings => ListenableBuilder(
                  key: const ValueKey(HomeTab.settings),
                  listenable: _deps.vault,
                  builder: (context, _) => SettingsPage(
                    settings: _deps.settings,
                    entryCount: _deps.vault.entries.length,
                    onBack: () => _selectTab(HomeTab.vault),
                    onExport: () => _deps.backupActions.export(context),
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
