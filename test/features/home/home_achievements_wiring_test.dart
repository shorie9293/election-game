import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen 実績バッジ導線', () {
    Future<void> pumpHome(WidgetTester tester, {VoidCallback? onOpen}) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
            onOpenAchievements: onOpen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('実績バッジのボタンが AppBar に表示される', (tester) async {
      await pumpHome(tester);

      expect(find.byKey(AppKeys.homeAchievementsButton), findsOneWidget);
      expect(find.byTooltip('実績バッジ'), findsOneWidget);
    });

    testWidgets('ボタンを押すとコールバックが発火する', (tester) async {
      var opened = 0;
      await pumpHome(tester, onOpen: () => opened++);

      await tester.tap(find.byKey(AppKeys.homeAchievementsButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(opened, 1);
    });

    testWidgets('onOpenAchievements 未指定でも描画が落ちない', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byKey(AppKeys.homeAchievementsButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
