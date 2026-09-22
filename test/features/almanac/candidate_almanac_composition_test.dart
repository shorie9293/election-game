import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/features/almanac/presentation/candidate_almanac_screen.dart';

/// イシコリドメ（親）が独自に撃つ不変条件の探針。
///
/// 眷属の試練は「絞り込み」と「並び替え」を別々に検証しているため、
/// 「絞り込み後の部分集合に対して並び替えが適用されるか」という合成の
/// 不変条件は誰も撃っていない。ここで独立に撃つ。
void main() {
  List<Candidate> probeCandidates() => [
        Candidate(
          id: 'x1',
          name: '甲野一郎',
          portraitKey: 'p1',
          faction: '甲の会',
          personality: '控えめ',
          policies: [
            Policy(
              title: '小さな政策',
              description: '効果は小さい',
              category: '経済',
              effects: const {'employment': 5},
            ),
          ],
        ),
        Candidate(
          id: 'x2',
          name: '甲野二郎',
          portraitKey: 'p2',
          faction: '甲の会',
          personality: '大胆',
          policies: [
            Policy(
              title: '大きな政策',
              description: '効果は大きい',
              category: '医療',
              effects: const {'healthcare': 100},
            ),
          ],
        ),
        Candidate(
          id: 'y1',
          name: '乙野三郎',
          portraitKey: 'p3',
          faction: '乙の会',
          personality: '別派閥',
          policies: [
            Policy(
              title: '最大の政策',
              description: '全体では最大',
              category: '治安',
              effects: const {'safety': 1000},
            ),
          ],
        ),
      ];

  Future<void> pumpAlmanac(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CandidateAlmanacScreen(candidatesOverride: probeCandidates()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CandidateAlmanacScreen 親探針（合成の不変条件）', () {
    testWidgets('派閥絞り込みと検索は AND で合成される', (tester) async {
      await pumpAlmanac(tester);

      // 甲の会に絞る
      await tester.tap(find.byKey(AppKeys.almanacFactionChip('甲の会')));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.almanacCandidateCard('y1')), findsNothing);
      expect(find.byKey(AppKeys.almanacCandidateCard('x1')), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('x2')), findsOneWidget);

      // さらに「二郎」で検索 → 甲の会かつ二郎 の1件のみ（AND）
      await tester.enterText(find.byKey(AppKeys.almanacSearchField), '二郎');
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.almanacCandidateCard('x1')), findsNothing);
      expect(find.byKey(AppKeys.almanacCandidateCard('x2')), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCandidateCard('y1')), findsNothing);
    });

    testWidgets('政策効果順は「絞り込み後の部分集合」に対して適用される', (tester) async {
      await pumpAlmanac(tester);

      // 全体最大は y1（safety 1000）。甲の会に絞れば y1 は母集合から外れる。
      await tester.tap(find.byKey(AppKeys.almanacFactionChip('甲の会')));
      await tester.pumpAndSettle();

      // 登録順では x1 が先頭（リスト先頭の y 座標が x1 の方が小さい）
      final x1TopBefore =
          tester.getTopLeft(find.byKey(AppKeys.almanacCandidateCard('x1'))).dy;
      final x2TopBefore =
          tester.getTopLeft(find.byKey(AppKeys.almanacCandidateCard('x2'))).dy;
      expect(x1TopBefore < x2TopBefore, isTrue);

      // 政策効果順へ切替 → 部分集合内の最大 x2 が先頭になる
      await tester.tap(find.byKey(AppKeys.almanacSortButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('政策効果順').last);
      await tester.pumpAndSettle();

      final x2TopAfter =
          tester.getTopLeft(find.byKey(AppKeys.almanacCandidateCard('x2'))).dy;
      final x1TopAfter =
          tester.getTopLeft(find.byKey(AppKeys.almanacCandidateCard('x1'))).dy;
      expect(x2TopAfter < x1TopAfter, isTrue);

      // 全体最大の y1 は絞り込みで除外されたまま（ソートが母集合を復元しない）
      expect(find.byKey(AppKeys.almanacCandidateCard('y1')), findsNothing);
    });

    testWidgets('件数表示は絞り込み後の件数と一致する', (tester) async {
      await pumpAlmanac(tester);

      expect(
        (tester.widget<Text>(find.byKey(AppKeys.almanacCountLabel))).data,
        '候補者 3人',
      );

      await tester.enterText(find.byKey(AppKeys.almanacSearchField), '甲野');
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Text>(find.byKey(AppKeys.almanacCountLabel))).data,
        '候補者 2人',
      );
    });
  });
}
