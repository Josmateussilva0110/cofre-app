import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/appear.dart';
import '../../domain/entities/entry.dart';
import 'wallet_card.dart';

/// Pilha de cartões no layout "carteira".
///
/// Usa `Stack` em vez de `ListView.builder` porque os cartões se sobrepõem; o cofre é local e pequeno.
class WalletStack extends StatelessWidget {
  const WalletStack({super.key, required this.entries, required this.onOpen, required this.onMenu});

  /// Quanto de cada cartão fica visível na pilha.
  static const double step = 72;

  final List<Entry> entries;
  final ValueChanged<Entry> onOpen;
  final void Function(Entry entry, Rect anchor) onMenu;

  @override
  Widget build(BuildContext context) {
    final count = entries.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s2, AppSpacing.s14, AppSpacing.s2, 0),
      child: SizedBox(
        height: (count - 1) * step + WalletCard.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (index, entry) in entries.indexed)
              Positioned(
                key: ValueKey(entry.id),
                top: index * step,
                left: 0,
                right: 0,
                child: Appear(
                  kind: AppearKind.rise,
                  duration: AppMotion.rise,
                  child: WalletCard(
                    entry: entry,
                    isLast: index == count - 1,
                    onOpen: () => onOpen(entry),
                    onMenu: (anchor) => onMenu(entry, anchor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
