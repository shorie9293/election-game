import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/help/domain/help_catalog.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';

void main() {
  group('HelpCatalog', () {
    const catalog = HelpCatalog();

    test('全トピックはチュートリアルの宣言順に並ぶ', () {
      final topics = catalog.allTopics;

      expect(topics.length, TutorialStep.values.length);
      expect(
        topics.map((t) => t.title).toList(),
        TutorialStep.values.map((s) => s.label).toList(),
      );
    });

    test('空クエリは全件を返す', () {
      expect(catalog.search('').length, catalog.allTopics.length);
    });

    test('空白のみのクエリは全件を返す', () {
      expect(catalog.search('   ').length, catalog.allTopics.length);
    });

    test('部分一致で絞り込める（本文も対象）', () {
      final hits = catalog.search('投票');

      expect(hits, isNotEmpty);
      expect(hits.length, lessThan(catalog.allTopics.length));
      expect(
        hits.every((t) => t.title.contains('投票') || t.body.contains('投票')),
        isTrue,
      );
    });

    test('該当なしなら空', () {
      expect(catalog.search('存在しない語句zzz'), isEmpty);
    });

    test('大文字小文字を無視する', () {
      final lower = catalog.search('npc');
      final upper = catalog.search('NPC');

      expect(lower, isNotEmpty);
      expect(upper.map((t) => t.id).toList(), lower.map((t) => t.id).toList());
    });

    test('絞り込み後も宣言順を維持する', () {
      final all = catalog.allTopics;
      final hits = catalog.search('選挙');

      expect(hits.length, greaterThan(1));
      final indexes = hits.map((t) => all.indexOf(t)).toList();
      final sorted = [...indexes]..sort();
      expect(indexes, sorted);
    });

    test('id は一意で title/body は非空', () {
      final topics = catalog.allTopics;
      final ids = topics.map((t) => t.id).toList();

      expect(ids.toSet().length, ids.length);
      for (final topic in topics) {
        expect(topic.title.trim(), isNotEmpty, reason: topic.id);
        expect(topic.body.trim(), isNotEmpty, reason: topic.id);
      }
    });

    test('本文はチュートリアル文言を再利用する（二重管理しない）', () {
      for (final step in TutorialStep.values) {
        final topic = catalog.allTopics.firstWhere((t) => t.id == step.name);
        expect(topic.body, step.description);
        expect(topic.title, step.label);
      }
    });
  });
}
