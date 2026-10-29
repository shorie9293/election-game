import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';
import 'package:election_game/features/settings/presentation/settings_hub_screen.dart';
import 'package:election_game/features/settings/presentation/theme_mode_settings_screen.dart';

/// 設定ハブに並ぶ全項目（ラベルと試験用Key）。
const _entries = <({String label, Key key})>[
  (label: 'テーマ設定', key: AppKeys.settingsHubThemeTile),
  (label: '文字サイズ', key: AppKeys.settingsHubTextScaleTile),
  (label: '動きを減らす', key: AppKeys.settingsHubReduceMotionTile),
  (label: 'サウンド', key: AppKeys.settingsHubSoundTile),
  (label: '通知設定', key: AppKeys.settingsHubReminderTile),
  (label: '静穏時間', key: AppKeys.settingsHubQuietHoursTile),
  (label: 'バックアップ', key: AppKeys.settingsHubBackupTile),
  (label: '自動バックアップ', key: AppKeys.settingsHubAutoBackupTile),
  (label: 'アプリロック', key: AppKeys.settingsHubAppLockTile),
  (label: 'クロスアプリ連携', key: AppKeys.settingsHubCrossAppTile),
  (label: 'アプリについて', key: AppKeys.settingsHubAboutTile),
];

Future<void> _pumpHub(WidgetTester tester, Widget hub) async {
  // 10項目が同時に描画される縦長の試験画面（スクロール不要で全件を観測する）。
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: hub));
  await tester.pumpAndSettle();
}

void main() {
  group('SettingsHubScreen', () {
    testWidgets('AppBar に「設定」が出る', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      expect(find.byKey(AppKeys.settingsHubScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('設定'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('全11項目のラベルが並ぶ', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      for (final entry in _entries) {
        expect(
          find.byKey(entry.key),
          findsOneWidget,
          reason: '${entry.label} のタイルが無い',
        );
        expect(
          find.text(entry.label),
          findsWidgets,
          reason: '${entry.label} のラベルが無い',
        );
      }
      expect(_entries.length, 11);
    });

    testWidgets('全項目に chevron（遷移アイコン）が付く', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(_entries.length));
    });

    testWidgets('各項目のタップで対応するビルダーが1回だけ呼ばれる', (tester) async {
      final calls = <String, int>{};
      for (final entry in _entries) {
        calls[entry.label] = 0;
      }
      WidgetBuilder counting(String label) => (_) {
            calls[label] = (calls[label] ?? 0) + 1;
            return Scaffold(
              appBar: AppBar(title: Text('probe:$label')),
              body: const Center(child: Text('probe body')),
            );
          };

      await _pumpHub(
        tester,
        SettingsHubScreen(
          themeModeScreenBuilder: counting('テーマ設定'),
          textScaleScreenBuilder: counting('文字サイズ'),
          reduceMotionScreenBuilder: counting('動きを減らす'),
          soundScreenBuilder: counting('サウンド'),
          reminderScreenBuilder: counting('通知設定'),
          quietHoursScreenBuilder: counting('静穏時間'),
          backupScreenBuilder: counting('バックアップ'),
          autoBackupScreenBuilder: counting('自動バックアップ'),
          appLockScreenBuilder: counting('アプリロック'),
          crossAppScreenBuilder: counting('クロスアプリ連携'),
          aboutScreenBuilder: counting('アプリについて'),
        ),
      );

      // タップ前は誰も呼ばれない（遅延生成）。
      expect(calls.values.every((n) => n == 0), isTrue);

      for (final entry in _entries) {
        await tester.tap(find.byKey(entry.key));
        await tester.pumpAndSettle();

        expect(
          find.text('probe:${entry.label}'),
          findsOneWidget,
          reason: '${entry.label} のビルダーが呼ばれていない',
        );
        expect(calls[entry.label], 1, reason: '${entry.label} の呼出回数');

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byKey(AppKeys.settingsHubScreen), findsOneWidget);
      }
      expect(calls.length, _entries.length);
    });

    testWidgets('ビルダー未指定なら実画面（テーマ設定）が開く', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      await tester.tap(find.byKey(AppKeys.settingsHubThemeTile));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.themeModeScreen), findsOneWidget);
    });

    testWidgets('ビルダー未指定なら実画面（アプリについて）が開く', (tester) async {
      await _pumpHub(tester, const SettingsHubScreen());

      await tester.tap(find.byKey(AppKeys.settingsHubAboutTile));
      await tester.pumpAndSettle();

      expect(find.text('アプリについて'), findsWidgets);
    });
  });

  group('設定ハブへの導線（テーマ設定画面）', () {
    testWidgets('テーマ設定画面の先頭に「設定ハブ」があり、タップでハブへ到達する', (tester) async {
      await _pumpHub(
        tester,
        ThemeModeSettingsScreen(
          currentMode: ThemeModeSetting.system,
          onModeChanged: (_) {},
        ),
      );

      expect(find.byKey(AppKeys.settingsHubEntry), findsOneWidget);
      expect(find.text('設定ハブ'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.settingsHubEntry));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.settingsHubScreen), findsOneWidget);
    });

    testWidgets('ハブから戻るとテーマ設定画面に帰る', (tester) async {
      await _pumpHub(
        tester,
        ThemeModeSettingsScreen(
          currentMode: ThemeModeSetting.dark,
          onModeChanged: (_) {},
        ),
      );

      await tester.tap(find.byKey(AppKeys.settingsHubEntry));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.settingsHubScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.settingsHubScreen), findsNothing);
      expect(find.byKey(AppKeys.themeModeScreen), findsOneWidget);
    });

    testWidgets('ハブはテーマ設定の現在値（dark）を引き継ぐ', (tester) async {
      await _pumpHub(
        tester,
        ThemeModeSettingsScreen(
          currentMode: ThemeModeSetting.dark,
          onModeChanged: (_) {},
        ),
      );

      await tester.tap(find.byKey(AppKeys.settingsHubEntry));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.settingsHubThemeTile));
      await tester.pumpAndSettle();

      final radio = tester.widget<RadioListTile<ThemeModeSetting>>(
        find.byKey(AppKeys.themeModeOption('dark')),
      );
      expect(radio.groupValue, ThemeModeSetting.dark);
    });

    testWidgets('テーマ設定画面の既存3択は導線追加後も残る', (tester) async {
      await _pumpHub(
        tester,
        ThemeModeSettingsScreen(
          currentMode: ThemeModeSetting.system,
          onModeChanged: (_) {},
        ),
      );

      expect(find.text('ライト'), findsOneWidget);
      expect(find.text('ダーク'), findsOneWidget);
      expect(find.text('システム'), findsOneWidget);
      expect(find.byKey(AppKeys.reduceMotionEntry), findsOneWidget);
    });
  });
}
