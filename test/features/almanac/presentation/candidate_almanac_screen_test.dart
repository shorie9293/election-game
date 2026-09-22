import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/services/candidate_almanac_service.dart';
import 'package:election_game/features/almanac/presentation/candidate_almanac_screen.dart';

void main() {
  final candidates = Candidate.samples();
  final profiles = CandidateAlmanacService.build(candidates);

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Candidate>? candidatesOverride,
  }) async {
    // 4人分のカードが全て viewport 内に build されるよう拡大する
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CandidateAlmanacScreen(candidatesOverride: candidatesOverride),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CandidateAlmanacScreen', () {
    testWidgets('タイトル・検索欄・件数表示が表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.almanacTitle), findsOneWidget);
      expect(find.text('候補者名鑑'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacSearchField), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCountLabel), findsOneWidget);
      expect(find.text('候補者 4人'), findsOneWidget);
    });

    testWidgets('4人全員のカードが表示される', (tester) async {
      await pumpScreen(tester);

      for (final candidate in candidates) {
        expect(
          find.byKey(AppKeys.almanacCandidateCard(candidate.id)),
          findsOneWidget,
        );
      }
      expect(find.byKey(AppKeys.almanacEmptyState), findsNothing);
    });

    testWidgets('派閥チップが「すべて」＋各派閥ぶん表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.almanacFactionAll), findsOneWidget);
      for (final faction in CandidateAlmanacService.factions(candidates)) {
        expect(find.byKey(AppKeys.almanacFactionChip(faction)), findsOneWidget);
        expect(find.text(faction), findsOneWidget);
      }
    });

    testWidgets('派閥絞り込みで他派閥のカードが消える', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.almanacFactionChip('発展の会')));
      await tester.pumpAndSettle();

      expect(find.text('候補者 1人'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_1')),
          findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_2')),
          findsNothing);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_3')),
          findsNothing);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_4')),
          findsNothing);
    });

    testWidgets('検索で名前を絞り込める', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(AppKeys.almanacSearchField),
        '佐藤',
      );
      await tester.pumpAndSettle();

      expect(find.text('候補者 1人'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_2')),
          findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_1')),
          findsNothing);
    });

    testWidgets('検索で派閥名でも絞り込める', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(AppKeys.almanacSearchField), '守り');
      await tester.pumpAndSettle();

      expect(find.text('候補者 1人'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_3')),
          findsOneWidget);
    });

    testWidgets('該当0件なら空状態が出る', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(AppKeys.almanacSearchField),
        '存在しない候補者',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.almanacEmptyState), findsOneWidget);
      expect(find.text('該当する候補者がいません'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacList), findsNothing);
      expect(find.text('候補者 0人'), findsOneWidget);
    });

    testWidgets('検索を空に戻すと絞り込みが解除される', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(AppKeys.almanacSearchField), '山田');
      await tester.pumpAndSettle();
      expect(find.text('候補者 1人'), findsOneWidget);

      await tester.enterText(find.byKey(AppKeys.almanacSearchField), '');
      await tester.pumpAndSettle();
      expect(find.text('候補者 4人'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacEmptyState), findsNothing);
    });

    testWidgets('政策効果順に切り替えると totalEffectScore 最大の候補者が先頭になる', (tester) async {
      await pumpScreen(tester);

      final expectedTop = CandidateAlmanacService.topByEffect(profiles)!;

      await tester.tap(find.byKey(AppKeys.almanacSortButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('政策効果順').last);
      await tester.pumpAndSettle();

      // 先頭カードの id を確認
      final listCardKeys = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(AppKeys.almanacList),
              matching: find.byWidgetPredicate(
                (w) =>
                    w.key is Key &&
                    (w.key as Key)
                        .toString()
                        .startsWith("[<'almanac_candidate_card_"),
              ),
            ),
          )
          .map((w) => (w.key as Key).toString())
          .toList();
      expect(
        listCardKeys.first,
        contains(expectedTop.candidate.id),
      );
      // 期待値: 政策効果順の1位は totalEffectScore 最大
      final topScore = profiles
          .map((p) => p.totalEffectScore)
          .reduce((a, b) => a > b ? a : b);
      expect(expectedTop.totalEffectScore, topScore);
    });

    testWidgets('ソート切替で先頭カードが変わる（登録順は candidate_1 が先頭）', (tester) async {
      await pumpScreen(tester);

      String firstCardId() {
        final keys = tester
            .widgetList<Container>(
              find.byWidgetPredicate(
                (w) =>
                    w.key is Key &&
                    (w.key as Key)
                        .toString()
                        .startsWith("[<'almanac_candidate_card_"),
              ),
            )
            .map((w) => (w.key as Key).toString())
            .toList();
        return keys.first;
      }

      expect(firstCardId(), contains('candidate_1'));

      await tester.tap(find.byKey(AppKeys.almanacSortButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('政策効果順').last);
      await tester.pumpAndSettle();

      final afterSort = firstCardId();
      final expectedTop = CandidateAlmanacService.topByEffect(profiles)!;
      expect(afterSort, contains(expectedTop.candidate.id));
      expect(afterSort, isNot(contains('candidate_1')));
    });

    testWidgets('カードを tap するとダイアログが開き公約タイトルが見える', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.almanacCandidateCard('candidate_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.almanacDetailDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(AppKeys.almanacDetailDialog),
          matching: find.text('山田太郎'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(AppKeys.almanacDetailDialog),
          matching: find.text('大規模開発'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(AppKeys.almanacDetailDialog),
          matching: find.text('減税'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('ダイアログに公約の説明・カテゴリ・効果が表示される', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.almanacCandidateCard('candidate_1')));
      await tester.pumpAndSettle();

      expect(find.text('公共事業で経済を活性化'), findsOneWidget);
      expect(find.text('カテゴリ: 経済'), findsNWidgets(2));
      expect(find.text('雇用: +10'), findsOneWidget);
      expect(find.text('環境: -5'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.almanacDetailCloseButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.almanacDetailDialog), findsNothing);
    });

    testWidgets('「すべて」チップで派閥絞り込みをリセットできる', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.almanacFactionChip('発展の会')));
      await tester.pumpAndSettle();
      expect(find.text('候補者 1人'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.almanacFactionAll));
      await tester.pumpAndSettle();
      expect(find.text('候補者 4人'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_4')),
          findsOneWidget);
    });

    testWidgets('candidatesOverride を渡すとその候補者だけ表示される', (tester) async {
      await pumpScreen(
        tester,
        candidatesOverride: [candidates.first],
      );

      expect(find.text('候補者 1人'), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_1')),
          findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('candidate_2')),
          findsNothing);
    });
  });
}