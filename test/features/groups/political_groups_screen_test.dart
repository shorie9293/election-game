import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/groups/presentation/political_groups_screen.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Candidate>? candidates,
  }) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: PoliticalGroupsScreen(candidatesOverride: candidates),
      ),
    );
    await tester.pump();
  }

  group('PoliticalGroupsScreen 政党の可視化', () {
    testWidgets('既定で5団体のカードが並ぶ', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.politicalGroupsScreen), findsOneWidget);
      expect(find.byKey(AppKeys.politicalGroupsCountLabel), findsOneWidget);
      expect(find.text('5団体'), findsOneWidget);
      for (final id in const [
        'group_development',
        'group_symbiosis',
        'group_defense',
        'group_green',
        'group_reform',
      ]) {
        expect(find.byKey(AppKeys.politicalGroupsCard(id)), findsOneWidget);
      }
    });

    testWidgets('検索で該当団体のみに絞り込まれる', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(AppKeys.politicalGroupsSearchField),
        '共生',
      );
      await tester.pump();

      expect(find.byKey(AppKeys.politicalGroupsCard('group_symbiosis')),
          findsOneWidget);
      expect(find.byKey(AppKeys.politicalGroupsCard('group_development')),
          findsNothing);
      expect(find.text('1団体'), findsOneWidget);
    });

    testWidgets('理念でも検索できる', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(AppKeys.politicalGroupsSearchField),
        '自然との調和',
      );
      await tester.pump();

      expect(find.byKey(AppKeys.politicalGroupsCard('group_green')),
          findsOneWidget);
      expect(find.text('1団体'), findsOneWidget);
    });

    testWidgets('象限チップで該当団体のみに絞り込まれる', (tester) async {
      await pumpScreen(tester);

      // 緑の会(-0.6, 0.4) と 共生の会(-0.3, 0.9) はどちらも 規制 × 社会保障重視
      await tester.tap(
        find.byKey(AppKeys.politicalGroupsQuadrantChip('規制 × 社会保障重視')),
      );
      await tester.pump();

      expect(find.byKey(AppKeys.politicalGroupsCard('group_green')),
          findsOneWidget);
      expect(find.byKey(AppKeys.politicalGroupsCard('group_symbiosis')),
          findsOneWidget);
      expect(find.byKey(AppKeys.politicalGroupsCard('group_development')),
          findsNothing);
      expect(find.text('2団体'), findsOneWidget);
    });

    testWidgets('0件になる検索で空状態が出る', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(AppKeys.politicalGroupsSearchField),
        '存在しない政党',
      );
      await tester.pump();

      expect(find.byKey(AppKeys.politicalGroupsEmptyState), findsOneWidget);
      expect(find.byKey(AppKeys.politicalGroupsList), findsNothing);
      expect(find.text('0団体'), findsOneWidget);
    });

    testWidgets('並び替えで経済軸の順序が逆になる', (tester) async {
      await pumpScreen(tester);

      List<String> visibleOrder() {
        final cards = tester
            .widgetList<InkWell>(find.byType(InkWell))
            .map((w) => w.key)
            .whereType<ValueKey<String>>()
            .map((k) => k.value)
            .where((v) => v.startsWith('political_groups_card_'))
            .toList();
        return cards;
      }

      // 既定は降順: 発展の会(0.8) → 改革の会(0.2) → 共生の会(-0.3) ...
      expect(visibleOrder().first, 'political_groups_card_group_development');

      await tester.tap(find.byKey(AppKeys.politicalGroupsSortButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('経済軸 昇順（規制→自由市場）').last);
      await tester.pumpAndSettle();

      // 昇順: 緑の会(-0.6) が先頭
      expect(visibleOrder().first, 'political_groups_card_group_green');
    });

    testWidgets('カードのタップで詳細ダイアログが開き、閉じられる', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.politicalGroupsCard('group_green')));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.politicalGroupsDetailDialog), findsOneWidget);
      expect(find.text('自然との調和'), findsWidgets);

      await tester.tap(find.byKey(AppKeys.politicalGroupsDetailCloseButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.politicalGroupsDetailDialog), findsNothing);
    });

    testWidgets('マップ上のマーカーは5政党分あり、タップで詳細が出る', (tester) async {
      await pumpScreen(tester);

      for (final id in const [
        'group_development',
        'group_symbiosis',
        'group_defense',
        'group_green',
        'group_reform',
      ]) {
        expect(find.byKey(AppKeys.politicalGroupsMarker(id)), findsOneWidget);
      }

      await tester.tap(
        find.byKey(AppKeys.politicalGroupsMarker('group_reform')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.politicalGroupsDetailDialog), findsOneWidget);
    });

    testWidgets('候補者ごとの支持政党が並ぶ（candidate_2 は2政党）', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.politicalGroupsSupportList), findsOneWidget);
      expect(
        find.byKey(AppKeys.politicalGroupsSupportRow('candidate_2')),
        findsOneWidget,
      );
      expect(
        find.textContaining('佐藤花子: 発展の会、共生の会（2政党）'),
        findsOneWidget,
      );
    });

    testWidgets('推薦候補なしの政党がサマリーに表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.politicalGroupsSummaryCard), findsOneWidget);
      expect(find.textContaining('推薦候補なしの政党: 緑の会'), findsOneWidget);
    });

    testWidgets('候補者を注入すると推薦候補の解決にその候補者が使われる', (tester) async {
      final custom = [
        Candidate.samples().first.copyWith(id: 'candidate_9', name: '検証太郎'),
      ];
      await pumpScreen(tester, candidates: custom);

      // 既定の支持IDは candidate_9 を含まないため、推薦候補なしが増える
      expect(find.textContaining('推薦を持つ政党: 0'), findsOneWidget);
      await pumpScreen(tester);
      expect(find.textContaining('推薦を持つ政党: 4'), findsOneWidget);
    });
  });

  group('HomeScreen 政党の可視化導線', () {
    testWidgets('ボタンが表示され、タップでコールバックが発火する', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
            onOpenPoliticalGroups: () => opened++,
          ),
        ),
      );

      expect(find.byKey(AppKeys.homePoliticalGroupsButton), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.homePoliticalGroupsButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(opened, 1);
    });

    testWidgets('未指定でも描画が落ちない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
          ),
        ),
      );

      await tester.tap(find.byKey(AppKeys.homePoliticalGroupsButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
