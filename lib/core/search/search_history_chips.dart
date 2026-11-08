import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';

/// 検索語の履歴チップ。履歴が空なら何も描かない。
class SearchHistoryChips extends StatelessWidget {
  const SearchHistoryChips({
    super.key,
    required this.entries,
    required this.onSelected,
  });

  /// 新しい順の検索語。
  final List<String> entries;

  /// チップがタップされたときに検索語を返す。
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      key: AppKeys.glossaryHistoryChips,
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in entries)
          ActionChip(
            key: AppKeys.glossaryHistoryChip(entry),
            label: Text(
              entry,
              style: const TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 12,
              ),
            ),
            backgroundColor: RetroPalette.panelBg,
            side: const BorderSide(color: RetroPalette.panelBorder),
            visualDensity: VisualDensity.compact,
            onPressed: () => onSelected(entry),
          ),
      ],
    );
  }
}
