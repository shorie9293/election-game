import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/features/help/domain/help_catalog.dart';
import 'package:election_game/features/help/domain/help_topic.dart';

/// 遊び方・ヘルプ画面 — 初回チュートリアルを読み返すための章立て＋検索。
///
/// 必須依存はゼロ。文言は [HelpCatalog]（= TutorialStep）にのみ依存する。
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, this.catalog = const HelpCatalog()});

  /// 章立ての供給元（試練で差し替え可能）。
  final HelpCatalog? catalog;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _query = '';

  HelpCatalog get _catalog => widget.catalog ?? const HelpCatalog();

  @override
  Widget build(BuildContext context) {
    final visible = _catalog.search(_query);

    return KeyedSubtree(
      key: AppKeys.helpScreen,
      child: Scaffold(
        backgroundColor: RetroPalette.bgDark,
        appBar: AppBar(
          title: const Text('遊び方・ヘルプ', key: AppKeys.helpTitle),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SemanticHelper.textField(
                testId: 'txt_help_search',
                label: 'ヘルプを検索',
                child: TextField(
                  key: AppKeys.helpSearchField,
                  decoration: InputDecoration(
                    hintText: '項目・本文で絞り込み',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: AppKeys.helpSearchClear,
                            icon: const Icon(Icons.clear),
                            tooltip: 'クリア',
                            onPressed: () => setState(() => _query = ''),
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: SemanticHelper.container(
                        testId: 'txt_help_empty',
                        child: const Text(
                          '該当するヘルプがありません',
                          key: AppKeys.helpEmptyState,
                          style: TextStyle(color: RetroPalette.textNormal),
                        ),
                      ),
                    )
                  : ListView(
                      key: AppKeys.helpList,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        for (final topic in visible) _topicTile(context, topic),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicTile(BuildContext context, HelpTopic topic) {
    return SemanticHelper.container(
      testId: 'item_help_topic_${topic.id}',
      explicitChildNodes: true,
      child: ExpansionTile(
        key: AppKeys.helpTopicTile(topic.id),
        leading: const Icon(Icons.help_outline),
        title: Text(
          topic.title,
          style: const TextStyle(
            color: RetroPalette.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topic.body,
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
        ],
      ),
    );
  }
}
