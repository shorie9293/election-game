import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen 候補者名鑑配線', () {
    testWidgets('AppBar の名鑑ボタンを tap すると onOpenAlmanac が1回呼ばれる',
        (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen(
              name: 'テスト太郎',
              job: Job.farmer,
              concerns: [Concern.agriculture],
              lifeParams: const {
                'lifeCost': 50,
                'healthcare': 50,
                'education': 50,
                'employment': 50,
                'environment': 50,
                'safety': 50,
              },
            ),
            societyState: SocietyState(
              happiness: 60.0,
              mood: 0.3,
              electionCount: 1,
            ),
            remainingTurns: 10,
            onOpenAlmanac: () => callCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(AppKeys.homeAlmanacButton), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.homeAlmanacButton));
      await tester.pump();

      expect(callCount, 1);
    });

    testWidgets('onOpenAlmanac 未指定でも名鑑ボタンが表示され tap しても落ちない',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen(
              name: 'テスト花子',
              job: Job.merchant,
              concerns: [Concern.economy],
              lifeParams: const {
                'lifeCost': 50,
                'healthcare': 50,
                'education': 50,
                'employment': 50,
                'environment': 50,
                'safety': 50,
              },
            ),
            societyState: SocietyState(
              happiness: 60.0,
              mood: 0.3,
              electionCount: 1,
            ),
            remainingTurns: 10,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(AppKeys.homeAlmanacButton), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.homeAlmanacButton));
      await tester.pump();
    });
  });
}