import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/glossary_term.dart';
import 'package:election_game/domain/services/glossary_service.dart';
import 'package:election_game/features/glossary/presentation/glossary_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  List<GlossaryTerm>? termsOverride,
}) async {
  await tester.pumpWidget(
    _wrap(GlossaryScreen(termsOverride: termsOverride)),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('起動時に全件表示・件数ラベルがcatalog件数と一致する', (tester) async {
    await _pumpScreen(tester);
    expect(find.byKey(AppKeys.glossaryTitle), findsOneWidget);
    expect(
      find.text('${GlossaryService.catalog.length}語'),
      findsOneWidget,
    );
    // ListView.builder は画面外を構築しないため、最下部までスクロールして全行を構築させる
    final seen = <String>{};
    for (var i = 0; i < 30 && seen.length < GlossaryService.catalog.length; i++) {
      for (final term in GlossaryService.catalog) {
        if (tester.any(find.byKey(AppKeys.glossaryTermTile(term.id)))) {
          seen.add(term.id);
        }
      }
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(seen.length, GlossaryService.catalog.length);
  });

  testWidgets('検索入力で絞り込まれ件数ラベルが減る', (tester) async {
    await _pumpScreen(tester);
    await tester.enterText(find.byKey(AppKeys.glossarySearchField), '選挙区');
    await tester.pump(const Duration(milliseconds: 300));

    final expected = GlossaryService.search('選挙区');
    expect(expected, isNotEmpty);
    expect(find.text('${expected.length}語'), findsOneWidget);
    expect(
      find.byKey(AppKeys.glossaryTermTile('shokyosentyoku_sei')),
      findsOneWidget,
    );
  });

  testWidgets('カテゴリChipタップで絞り込まれる', (tester) async {
    await _pumpScreen(tester);
    await tester.tap(
      find.byKey(AppKeys.glossaryCategoryChip('選挙制度')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    final expected = GlossaryService.filterByCategory(
      GlossaryService.catalog,
      '選挙制度',
    );
    expect(find.text('${expected.length}語'), findsOneWidget);
    // 投票カテゴリの用語は非表示
    expect(find.byKey(AppKeys.glossaryTermTile('kiken')), findsNothing);
  });

  testWidgets('行タップで詳細ダイアログが開く', (tester) async {
    await _pumpScreen(tester);
    await tester.tap(
      find.byKey(AppKeys.glossaryTermTile('shokyosentyoku_sei')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('小選挙区制'), findsWidgets);
    expect(find.text('関連用語'), findsOneWidget);
    // 閉じる
    await tester.tap(find.text('閉じる'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('0件になる検索で空状態が出る', (tester) async {
    await _pumpScreen(tester);
    await tester.enterText(
      find.byKey(AppKeys.glossarySearchField),
      '存在しない用語xyz',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(AppKeys.glossaryEmptyState), findsOneWidget);
    expect(find.text('0語'), findsOneWidget);
  });

  testWidgets('termsOverride を渡したらその用語のみ表示される', (tester) async {
    final override = [
      GlossaryTerm(
        id: 'test_a',
        term: 'テスト用語A',
        reading: 'てすとようごえー',
        category: '選挙制度',
      ),
    ];
    await _pumpScreen(tester, termsOverride: override);

    expect(find.text('1語'), findsOneWidget);
    expect(find.byKey(AppKeys.glossaryTermTile('test_a')), findsOneWidget);
    expect(
      find.byKey(AppKeys.glossaryTermTile('shokyosentyoku_sei')),
      findsNothing,
    );
  });
}
