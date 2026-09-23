import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';
import 'package:election_game/features/settings/presentation/theme_mode_settings_screen.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ThemeModeSetting currentMode,
  required ValueChanged<ThemeModeSetting> onModeChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ThemeModeSettingsScreen(
        currentMode: currentMode,
        onModeChanged: onModeChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ThemeModeSettingsScreen', () {
    testWidgets('3択（ライト/ダーク/システム）が表示される', (tester) async {
      await _pumpScreen(
        tester,
        currentMode: ThemeModeSetting.system,
        onModeChanged: (_) {},
      );

      expect(find.text('ライト'), findsOneWidget);
      expect(find.text('ダーク'), findsOneWidget);
      expect(find.text('システム'), findsOneWidget);
    });

    testWidgets('現在のモードの Radio が選択されている', (tester) async {
      await _pumpScreen(
        tester,
        currentMode: ThemeModeSetting.dark,
        onModeChanged: (_) {},
      );

      final darkRadioFinder = find.byKey(
        const Key('theme_mode_option_dark'),
      );
      expect(darkRadioFinder, findsOneWidget);
      final radio = tester.widget<RadioListTile<ThemeModeSetting>>(
        darkRadioFinder,
      );
      expect(radio.groupValue, ThemeModeSetting.dark);
    });

    testWidgets('tap で onModeChanged が呼ばれる', (tester) async {
      ThemeModeSetting? captured;
      await _pumpScreen(
        tester,
        currentMode: ThemeModeSetting.system,
        onModeChanged: (mode) => captured = mode,
      );

      await tester.tap(find.byKey(const Key('theme_mode_option_light')));
      await tester.pumpAndSettle();

      expect(captured, ThemeModeSetting.light);
    });

    testWidgets('ダークを選択すると onModeChanged に dark が渡る', (tester) async {
      ThemeModeSetting? captured;
      await _pumpScreen(
        tester,
        currentMode: ThemeModeSetting.light,
        onModeChanged: (mode) => captured = mode,
      );

      await tester.tap(find.byKey(const Key('theme_mode_option_dark')));
      await tester.pumpAndSettle();

      expect(captured, ThemeModeSetting.dark);
    });
  });
}