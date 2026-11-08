import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/search/search_history_chips.dart';
import 'package:election_game/core/search/search_history_store.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/glossary_term.dart';
import 'package:election_game/features/glossary/presentation/glossary_screen.dart';

/// 保存内容をメモリに保持するだけのフェイク（プラグイン非依存）。
class _FakeStore implements SearchHistoryStore {
  _FakeStore([List<String> initial = const <String>[]])
      : _entries = List<String>.from(initial);

  List<String> _entries;
  int saveCount = 0;

  List<String> get entries => List<String>.unmodifiable(_entries);

  @override
  Future<List<String>> load() async => List<String>.from(_entries);

  @override
  Future<void> save(List<String> entries) async {
    saveCount++;
    _entries = List<String>.from(entries);
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

Widget _chips(List<String> entries, ValueChanged<String> onSelected) {
  return _wrap(
    Scaffold(
      body: SearchHistoryChips(entries: entries, onSelected: onSelected),
    ),
  );
}

final _terms = <GlossaryTerm>[
  GlossaryTerm(
    id: 'shokyosentyoku_sei',
    term: '小選挙区制',
    reading: 'しょうせんきょくせい',
    category: '選挙制度',
  ),
  GlossaryTerm(
    id: 'hirei_daihyo',
    term: '比例代表制',
    reading: 'ひれいだいひょうせい',
    category: '選挙制度',
  ),
  GlossaryTerm(
    id: 'kiken',
    term: '棄権',
    reading: 'きけん',
    category: '投票',
  ),
];

Future<void> _pumpScreen(WidgetTester tester, {_FakeStore? store}) async {
  await tester.pumpWidget(
    _wrap(
      GlossaryScreen(
        termsOverride: _terms,
        searchHistoryStore: store ?? _FakeStore(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('SearchHistoryChips', () {
    testWidgets('履歴が空なら何も描かない', (tester) async {
      await tester.pumpWidget(_chips(const <String>[], (_) {}));
      expect(find.byType(ActionChip), findsNothing);
      expect(find.byKey(AppKeys.glossaryHistoryChips), findsNothing);
    });

    testWidgets('履歴の数だけチップを表示する', (tester) async {
      await tester.pumpWidget(_chips(const <String>['選挙', '投票'], (_) {}));
      expect(find.byType(ActionChip), findsNWidgets(2));
      expect(find.widgetWithText(ActionChip, '選挙'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, '投票'), findsOneWidget);
      expect(
        find.byKey(AppKeys.glossaryHistoryChip('選挙')),
        findsOneWidget,
      );
    });

    testWidgets('チップのタップで検索語が通知される', (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(
        _chips(const <String>['選挙', '投票'], selected.add),
      );
      await tester.tap(find.byKey(AppKeys.glossaryHistoryChip('投票')));
      await tester.pump();
      expect(selected, <String>['投票']);
    });
  });

  group('GlossaryScreen への配線', () {
    testWidgets('保存済み履歴がチップとして表示される', (tester) async {
      await _pumpScreen(tester, store: _FakeStore(<String>['比例代表']));
      expect(find.byKey(AppKeys.glossaryHistoryChips), findsOneWidget);
      expect(
        find.byKey(AppKeys.glossaryHistoryChip('比例代表')),
        findsOneWidget,
      );
    });

    testWidgets('履歴が無ければチップは出ない', (tester) async {
      await _pumpScreen(tester);
      expect(find.byKey(AppKeys.glossaryHistoryChips), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('チップをタップすると検索欄と絞り込みが更新される', (tester) async {
      await _pumpScreen(tester, store: _FakeStore(<String>['小選挙区']));
      await tester.tap(find.byKey(AppKeys.glossaryHistoryChip('小選挙区')));
      await tester.pump(const Duration(milliseconds: 300));

      final field = tester.widget<TextField>(
        find.byKey(AppKeys.glossarySearchField),
      );
      expect(field.controller?.text, '小選挙区');
      expect(find.text('1語'), findsOneWidget);
      expect(
        find.byKey(AppKeys.glossaryTermTile('shokyosentyoku_sei')),
        findsOneWidget,
      );
      expect(find.byKey(AppKeys.glossaryTermTile('kiken')), findsNothing);
    });

    testWidgets('onSubmitted で現在の検索語が保存される', (tester) async {
      final store = _FakeStore();
      await _pumpScreen(tester, store: store);

      await tester.enterText(
        find.byKey(AppKeys.glossarySearchField),
        '比例代表',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 300));

      expect(store.entries, <String>['比例代表']);
      expect(find.byKey(AppKeys.glossaryHistoryChip('比例代表')), findsOneWidget);
    });

    testWidgets('空の検索語は onSubmitted でも保存しない', (tester) async {
      final store = _FakeStore();
      await _pumpScreen(tester, store: store);

      await tester.enterText(find.byKey(AppKeys.glossarySearchField), '   ');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 300));

      expect(store.saveCount, 0);
      expect(store.entries, isEmpty);
    });

    testWidgets('dispose 時に検索語が保存される', (tester) async {
      final store = _FakeStore();
      await _pumpScreen(tester, store: store);

      await tester.enterText(find.byKey(AppKeys.glossarySearchField), '棄権');
      await tester.pump();

      // 画面を破棄して dispose を走らせる。
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      expect(store.entries, <String>['棄権']);
    });

    testWidgets('検索語が空のまま dispose されたら保存しない', (tester) async {
      final store = _FakeStore();
      await _pumpScreen(tester, store: store);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      expect(store.saveCount, 0);
    });
  });
}
