import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/glossary_term.dart';
import 'package:election_game/domain/services/glossary_service.dart';

/// 用語集の並び替え順ラベル
extension _GlossarySortOrderLabel on GlossarySortOrder {
  String get label =>
      this == GlossarySortOrder.nameAsc ? '読み順' : 'カテゴリ順';
}

/// 政治用語辞典画面 — 用語を検索・絞り込み・並び替えして学べる
class GlossaryScreen extends StatefulWidget {
  /// テスト等で用語を差し替えたい場合。null なら [GlossaryService.catalog] を使う。
  final List<GlossaryTerm>? termsOverride;

  const GlossaryScreen({super.key, this.termsOverride});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _query = '';
  String? _selectedCategory;
  GlossarySortOrder _sortOrder = GlossarySortOrder.nameAsc;

  // getter にせよ。late final で widget を捕捉すると State 再利用時に
  // termsOverride の差し替えが反映されない（既知の禍津）。
  List<GlossaryTerm> get _terms =>
      widget.termsOverride ?? GlossaryService.allTerms();

  List<GlossaryTerm> get _visible => GlossaryService.apply(
        _terms,
        query: _query,
        category: _selectedCategory,
        sort: _sortOrder,
      );

  void _showDetail(BuildContext context, GlossaryTerm term) {
    showDialog<void>(
      context: context,
      builder: (_) => _GlossaryDetailDialog(initialTerm: term),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = GlossaryService.categories;
    final visible = _visible;

    return KeyedSubtree(
      key: AppKeys.glossaryScreen,
      child: Scaffold(
        backgroundColor: RetroPalette.bgDark,
        appBar: AppBar(
          title: const Text('政治用語辞典', key: AppKeys.glossaryTitle),
          actions: [
            PopupMenuButton<GlossarySortOrder>(
              key: AppKeys.glossarySortButton,
              icon: const Icon(Icons.sort),
              tooltip: '並び替え',
              onSelected: (order) => setState(() => _sortOrder = order),
              itemBuilder: (context) => GlossarySortOrder.values
                  .map(
                    (order) => PopupMenuItem<GlossarySortOrder>(
                      value: order,
                      child: Text(order.label),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: AppKeys.glossarySearchField,
                decoration: InputDecoration(
                  hintText: '用語・読みで絞り込み',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: AppKeys.glossarySearchClear,
                          icon: const Icon(Icons.clear),
                          tooltip: 'クリア',
                          onPressed: () => setState(() => _query = ''),
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    key: AppKeys.glossaryCategoryFilterAll,
                    label: const Text('すべて'),
                    selected: _selectedCategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  for (final category in categories) ...[
                    FilterChip(
                      key: AppKeys.glossaryCategoryChip(category),
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${visible.length}語',
                  key: AppKeys.glossaryListCount,
                  style: const TextStyle(
                    color: RetroPalette.textNormal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text(
                        '該当する用語がありません',
                        key: AppKeys.glossaryEmptyState,
                        style: TextStyle(color: RetroPalette.textNormal),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final term = visible[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            key: AppKeys.glossaryTermTile(term.id),
                            decoration: BoxDecoration(
                              color: RetroPalette.panelBg,
                              border: Border.all(
                                color: RetroPalette.panelBorder,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showDetail(context, term),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        term.term,
                                        style: const TextStyle(
                                          color: RetroPalette.gold,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${term.reading} — ${term.category}',
                                        style: const TextStyle(
                                          color: RetroPalette.textNormal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 用語の詳細ダイアログ。関連用語をタップすると同じダイアログ内で切替える。
class _GlossaryDetailDialog extends StatefulWidget {
  final GlossaryTerm initialTerm;

  const _GlossaryDetailDialog({required this.initialTerm});

  @override
  State<_GlossaryDetailDialog> createState() => _GlossaryDetailDialogState();
}

class _GlossaryDetailDialogState extends State<_GlossaryDetailDialog> {
  late GlossaryTerm _term = widget.initialTerm;

  @override
  Widget build(BuildContext context) {
    final related = GlossaryService.relatedOf(_term);
    return AlertDialog(
      backgroundColor: RetroPalette.panelBg,
      title: Text(
        _term.term,
        style: const TextStyle(color: RetroPalette.gold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              '${_term.reading} — ${_term.category}',
              style: const TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _term.shortDefinition,
              style: const TextStyle(
                color: RetroPalette.textAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _term.description,
              style: const TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 12,
              ),
            ),
            if (related.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '関連用語',
                style: TextStyle(
                  color: RetroPalette.textAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              for (final relatedTerm in related)
                TextButton(
                  onPressed: () => setState(() => _term = relatedTerm),
                  child: Text(
                    relatedTerm.term,
                    style: const TextStyle(color: RetroPalette.gold),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '閉じる',
            style: TextStyle(color: RetroPalette.textAccent),
          ),
        ),
      ],
    );
  }
}
