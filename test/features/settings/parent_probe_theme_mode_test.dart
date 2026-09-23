import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/core/theme/theme_mode_repository.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';
import 'package:election_game/features/settings/presentation/theme_mode_settings_screen.dart';

/// 親（イシコリ）の探針 — 合成の不変条件を撃つ。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('親探針: テーマ定義の対称性', () {
    test('lightThemeData は light、既存 themeData は dark のまま', () {
      expect(RetroTheme.lightThemeData.brightness, Brightness.light);
      expect(RetroTheme.themeData.brightness, Brightness.dark);
      expect(
        RetroTheme.lightThemeData.scaffoldBackgroundColor,
        isNot(RetroTheme.themeData.scaffoldBackgroundColor),
      );
    });
  });

  group('親探針: 永続化の往復と不正値', () {
    test('save → load は同じ設定を返し、実キーに載る', () async {
      const repo = ThemeModeRepository();
      await repo.saveThemeMode(ThemeModeSetting.dark);
      expect(await repo.loadThemeMode(), ThemeModeSetting.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('election_game_theme_mode'), 'dark');
    });

    test('不正な保存値は null を返し、fromStorageKey は system に落ちる', () async {
      SharedPreferences.setMockInitialValues(
        {'election_game_theme_mode': 'solar'},
      );
      const repo = ThemeModeRepository();
      expect(await repo.loadThemeMode(), isNull);
      expect(ThemeModeSetting.fromStorageKey('solar'), ThemeModeSetting.system);
      expect(ThemeModeSetting.fromStorageKey(null), ThemeModeSetting.system);
    });
  });

  group('親探針: 画面 → onModeChanged の合成', () {
    testWidgets('ダークを選ぶと dark が1回だけ通知される', (tester) async {
      final received = <ThemeModeSetting>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ThemeModeSettingsScreen(
            currentMode: ThemeModeSetting.system,
            onModeChanged: received.add,
          ),
        ),
      );

      expect(find.text('ライト'), findsOneWidget);
      expect(find.text('ダーク'), findsOneWidget);
      expect(find.text('システム'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.themeModeOption('dark')));
      await tester.pumpAndSettle();

      expect(received, [ThemeModeSetting.dark]);
    });
  });
}
