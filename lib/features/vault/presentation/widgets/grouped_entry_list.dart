import 'package:flutter/widgets.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/entities/entry.dart';
import '../controllers/vault_controller.dart';
import 'entry_row.dart';

/// Lista de senhas agrupada por letra.
class GroupedEntryList extends StatelessWidget {
  const GroupedEntryList({
    super.key,
    required this.groups,
    required this.padding,
    required this.onOpen,
    required this.onCopy,
    required this.onMenu,
  });

  final List<EntryGroup> groups;
  final EdgeInsetsGeometry padding;
  final ValueChanged<Entry> onOpen;
  final ValueChanged<Entry> onCopy;
  final void Function(Entry entry, Rect anchor) onMenu;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: groups.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(top: index > 0 ? AppSpacing.s18 : 0),
        child: _EntryGroupSection(group: groups[index], onOpen: onOpen, onCopy: onCopy, onMenu: onMenu),
      ),
    );
  }
}

class _EntryGroupSection extends StatelessWidget {
  const _EntryGroupSection({required this.group, required this.onOpen, required this.onCopy, required this.onMenu});

  final EntryGroup group;
  final ValueChanged<Entry> onOpen;
  final ValueChanged<Entry> onCopy;
  final void Function(Entry entry, Rect anchor) onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(group.letter, style: styles.groupLetter.copyWith(color: colors.accent)),
              const SizedBox(width: AppSpacing.s8),
              Text(
                AppStrings.groupCount(group.entries.length),
                style: styles.labelStrong.copyWith(color: colors.faint),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Container(
          decoration: AppDecorations.surface(colors, radius: AppRadius.r24),
          child: Column(
            children: [
              for (final (index, entry) in group.entries.indexed)
                EntryRow(
                  entry: entry,
                  isFirst: index == 0,
                  onOpen: () => onOpen(entry),
                  onCopy: () => onCopy(entry),
                  onMenu: (anchor) => onMenu(entry, anchor),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
