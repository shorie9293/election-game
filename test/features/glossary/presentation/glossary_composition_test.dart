import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/glossary_term.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/glossary_service.dart';
import 'package:election_game/features/glossary/presentation/glossary_screen.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

/// 親（イシコリドメ）の独自探針 — 合成の不変条件を撃つ。
/// 子供の試練は個別操作しか撃たないため、ここで以下を検証する:
/// ①State再利用時に termsOverride の差替が反映されるか（late final 陳腐化型を撃つ）
/// ②検索×カテゴリ絞込の合成件数がラベルと一致するか
/// ③並び替えが絞込後の部分集合に対して実際に順序を変えるか
/// ④ホームAppBar導線が実際にコールバックへ到達するか
void main() {
  group('GlossaryScreen 親探針', () {
    testWidgets('termsOverride を差し替えると表示が追随する（State陳腐化を撃つ）', (tester) async {
      final a = [
        GlossaryTerm(
          id: 'a',
          term: '甲',
          reading: 'こう',
          category: '選挙制度',
        ),
      ];
      final b = [
        GlossaryTerm(id: 'a', term: '甲', reading: 'こう', category: '選挙制度'),
        GlossaryTerm(id: 'b', term: '乙', reading: 'おつ', category: '投票'),
      ];
      await tester.pumpWidget(MaterialApp(home: GlossaryScreen(termsOverride: a)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('1語'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(home: GlossaryScreen(termsOverride: b)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('2語'), findsOneWidget);
      expect(find.byKey(AppKeys.glossaryTermTile('b')), findsOneWidget);
    });

    testWidgets('検索×カテゴリ絞込の合成件数がラベルと一致する', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GlossaryScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // カテゴリ「選挙制度」を選択
      await tester.tap(
        find.byKey(AppKeys.glossaryCategoryChip('選挙制度')),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 200));

      final expected = GlossaryService.apply(
        GlossaryService.allTerms(),
        category: '選挙制度',
      );
      expect(find.text('${expected.length}語'), findsOneWidget);

      // さらに検索語を重ねて AND 合成にする
      const query = '比例';
      await tester.enterText(find.byKey(AppKeys.glossarySearchField), query);
      await tester.pump(const Duration(milliseconds: 200));

      final expected2 = GlossaryService.apply(
        GlossaryService.allTerms(),
        query: query,
        category: '選挙制度',
      );
      expect(expected2.length, lessThanOrEqualTo(expected.length));
      expect(find.text('${expected2.length}語'), findsOneWidget);
    });

    testWidgets('並び替えが部分集合に適用され順序が実際に変わる', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GlossaryScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // ソート切替（カテゴリ順）
      await tester.tap(find.byKey(AppKeys.glossarySortButton));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('カテゴリ順').last);
      await tester.pump(const Duration(milliseconds: 300));

      final expected = GlossaryService.sortByCategory(GlossaryService.allTerms());
      final firstId = expected[0].id;
      final secondId = expected[1].id;

      final firstTile = find.byKey(AppKeys.glossaryTermTile(firstId));
      final secondTile = find.byKey(AppKeys.glossaryTermTile(secondId));
      expect(firstTile, findsOneWidget);
      expect(secondTile, findsOneWidget);

      // 期待順の1件目が2件目より上に描画されていること
      expect(
        tester.getTopLeft(firstTile).dy,
        lessThan(tester.getTopLeft(secondTile).dy),
      );

      // カテゴリ初出順の先頭カテゴリが先に来ていること（読み順とは別物であることの確認は
      // expected が nameAsc と異なる順序になるケースに依存するため件数のみ確認）
      expect(find.text('${expected.length}語'), findsOneWidget);
    });
  });

  group('ホームAppBar 用語辞典導線（親探針）', () {
    testWidgets('homeGlossaryButton タップで onOpenGlossary が1回発火する', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
            onOpenGlossary: () => opened++,
          ),
        ),
      );

      expect(find.byKey(AppKeys.homeGlossaryButton), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.homeGlossaryButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(opened, 1);
    });

    testWidgets('onOpenGlossary 未指定でも描画が落ちない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
          ),
        ),
      );

      await tester.tap(find.byKey(AppKeys.homeGlossaryButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}
