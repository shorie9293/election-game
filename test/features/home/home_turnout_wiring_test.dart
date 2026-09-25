import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen 投票率導線', () {
    testWidgets('投票率ボタンが AppBar に表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
          ),
        ),
      );

      expect(find.byKey(AppKeys.homeTurnoutButton), findsOneWidget);
    });

    testWidgets('投票率ボタンを押すとコールバックが発火する', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
            onOpenTurnout: () => opened++,
          ),
        ),
      );

      await tester.tap(find.byKey(AppKeys.homeTurnoutButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(opened, 1);
    });

    testWidgets('onOpenTurnout 未指定でも描画が落ちない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
            societyState: SocietyState.initial(),
            remainingTurns: 5,
          ),
        ),
      );

      await tester.tap(find.byKey(AppKeys.homeTurnoutButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
