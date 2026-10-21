import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/theme/reduce_motion_repository.dart';
import 'package:election_game/core/theme/reduce_motion_setting.dart';
import 'package:election_game/features/settings/presentation/reduce_motion_settings_screen.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  ReduceMotionRepository? repository,
  ReduceMotionSetting? initial,
  ValueChanged<ReduceMotionSetting>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ReduceMotionSettingsScreen(
        repository: repository,
        initial: initial,
        onChanged: onChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ReduceMotionSettingsScreen', () {
    testWidgets('3択（システム/有効/減らす）が描画される', (tester) async {
      await _pumpScreen(tester, initial: ReduceMotionSetting.system);

      for (final setting in ReduceMotionSetting.values) {
        expect(
          find.byKey(ValueKey('reduce_motion_option_${setting.storageKey}')),
          findsOneWidget,
        );
      }
      expect(find.text('システムに従う'), findsOneWidget);
      expect(find.text('動きを有効'), findsOneWidget);
      // 「動きを減らす」は AppBar タイトルにも現れるため、選択肢内に限定する。
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reduce_motion_option_on')),
          matching: find.text('動きを減らす'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('initial が選択状態に反映される', (tester) async {
      await _pumpScreen(tester, initial: ReduceMotionSetting.on);

      final tile = tester.widget<RadioListTile<ReduceMotionSetting>>(
        find.byKey(const ValueKey('reduce_motion_option_on')),
      );
      expect(tile.groupValue, ReduceMotionSetting.on);
    });

    testWidgets('repository 省略時は system が既定', (tester) async {
      await _pumpScreen(tester);

      final tile = tester.widget<RadioListTile<ReduceMotionSetting>>(
        find.byKey(const ValueKey('reduce_motion_option_system')),
      );
      expect(tile.groupValue, ReduceMotionSetting.system);
    });

    testWidgets('タップで repository.save に到達する', (tester) async {
      final repository = InMemoryReduceMotionRepository();
      await _pumpScreen(tester, repository: repository);

      await tester.tap(find.byKey(const ValueKey('reduce_motion_option_on')));
      await tester.pumpAndSettle();

      expect(repository.saveCount, 1);
      expect(repository.saved, ReduceMotionSetting.on);
    });

    testWidgets('タップで onChanged が発火する', (tester) async {
      ReduceMotionSetting? captured;
      await _pumpScreen(
        tester,
        onChanged: (setting) => captured = setting,
      );

      await tester.tap(find.byKey(const ValueKey('reduce_motion_option_off')));
      await tester.pumpAndSettle();

      expect(captured, ReduceMotionSetting.off);
    });

    testWidgets('タップ後は選択状態が切り替わる', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('reduce_motion_option_on')));
      await tester.pumpAndSettle();

      final tile = tester.widget<RadioListTile<ReduceMotionSetting>>(
        find.byKey(const ValueKey('reduce_motion_option_on')),
      );
      expect(tile.groupValue, ReduceMotionSetting.on);
    });
  });
}