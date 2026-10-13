import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../controllers/vault_controller.dart';
import '../widgets/grouped_entry_list.dart';
import '../widgets/vault_empty_state.dart';
import '../widgets/vault_header.dart';
import '../widgets/vault_search_bar.dart';
import 'entry_actions.dart';

/// Tela principal: lista de senhas agrupada por letra, com busca.
class VaultPage extends StatefulWidget {
  const VaultPage({super.key, required this.vault, required this.actions, required this.onLock, this.notice});

  final VaultController vault;
  final EntryActions actions;
  final VoidCallback onLock;

  /// Aviso opcional acima da busca (ex.: lembrete de backup).
  final Widget? notice;

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  late final _query = TextEditingController(text: widget.vault.query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: widget.vault,
      builder: (context, _) {
        final vault = widget.vault;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topPadding),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s10, AppSpacing.s20, 0),
              child: VaultHeader(totalCount: vault.entries.length, weakCount: vault.weakCount, onLock: widget.onLock),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s22, AppSpacing.s20, AppSpacing.s14),
              child: _PageTitle(),
            ),
            if (widget.notice case final notice?)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
                child: notice,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
              child: VaultSearchBar(controller: _query, onChanged: vault.search),
            ),
            Expanded(
              child: _EntryList(vault: vault, actions: widget.actions),
            ),
          ],
        );
      },
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Symbols.key_vertical_rounded, size: AppSizes.icon24, color: context.appColors.muted),
      const SizedBox(width: AppSpacing.s10),
      Text(AppStrings.passwordsTitle, style: context.textStyles.headline),
    ],
  );
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.vault, required this.actions});

  final VaultController vault;
  final EntryActions actions;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.s16,
      AppSpacing.s2,
      AppSpacing.s16,
      AppSizes.navClearance + MediaQuery.paddingOf(context).bottom,
    );
    final entries = vault.visibleEntries;

    if (vault.status == VaultStatus.loading) return const SizedBox.shrink();
    if (entries.isEmpty) {
      final reason = switch (vault.status) {
        VaultStatus.loadFailed => VaultEmptyReason.loadFailed,
        _ when vault.entries.isNotEmpty => VaultEmptyReason.noResults,
        _ => VaultEmptyReason.noEntries,
      };
      return SingleChildScrollView(
        padding: padding,
        child: VaultEmptyState(reason: reason),
      );
    }

    return GroupedEntryList(
      groups: vault.groupedEntries,
      padding: padding,
      onOpen: (entry) => actions.showDetail(context, entry),
      onCopy: actions.copyPassword,
      onMenu: (entry, anchor) => actions.showMenu(context, entry, anchor),
    );
  }
}
