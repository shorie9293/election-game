import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/help/presentation/help_screen.dart';
import 'package:election_game/features/settings/presentation/settings_hub_screen.dart';

/// ヘルプ追加前から存在する項目（並び順の基準）。
const _legacyLabels = <String>[
  '不具合の報告',
  'テーマ設定',
  '文字サイズ',
  '動きを減らす',
  'サウンド',
  '通知設定',
  '静穏時間',
  'バックアップ',
  '自動バックアップ',
  'アプリロック',
  'クロスアプリ連携',
  'アプリについて',
];

Future<void> _pumpHub(WidgetTester tester, Widget hub) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: hub));
  await tester.pumpAndSettle();
}

List<String> _tileLabels(WidgetTester tester) => tester
    .widgetList<ListTile>(find.byType(ListTile))
    .map((t) => (t.title as Text?)?.data ?? '')
    .where((s) => s.isNotEmpty)
    .toList();

void main() {
  group('設定ハブの「遊び方・ヘルプ」', () {
    testWidgets('ヘルプ項目が1つだけ表示される', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      expect(find.byKey(AppKeys.settingsHubHelpTile), findsOneWidget);
      expect(find.text('遊び方・ヘルプ'), findsOneWidget);
    });

    testWidgets('タップで HelpScreen へ遷移する（実画面）', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      await tester.tap(find.byKey(AppKeys.settingsHubHelpTile));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.helpScreen), findsOneWidget);
    });

    testWidgets('注入ビルダーが1回だけ呼ばれる', (tester) async {
      var calls = 0;
      await _pumpHub(
        tester,
        SettingsHubScreen(
          helpScreenBuilder: (_) {
            calls++;
            return const Scaffold(
              appBar: null,
              body: Center(child: Text('probe:help')),
            );
          },
        ),
      );

      expect(calls, 0);
      await tester.tap(find.byKey(AppKeys.settingsHubHelpTile));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('probe:help'), findsOneWidget);
      expect(find.byKey(AppKeys.helpScreen), findsNothing);
    });

    testWidgets('既存項目の並びと件数は変わらない', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      final labels = _tileLabels(tester);
      // 既存12項目 + ヘルプ1項目 + 連携状況1項目。
      expect(labels.length, _legacyLabels.length + 2);
      expect(labels.take(_legacyLabels.length).toList(), _legacyLabels);
      expect(labels.contains('遊び方・ヘルプ'), isTrue);
      expect(labels.contains('連携状況（現世間の受け渡し）'), isTrue);
    });
  });

  test('HelpScreen 型が公開されている', () {
    expect(const HelpScreen(), isA<HelpScreen>());
  });
}
