import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('homePredictionButton をタップすると onOpenPrediction が1回呼ばれる',
      (tester) async {
    var callCount = 0;
    final citizen = Citizen(
      name: 'テスト太郎',
      job: Job.farmer,
      concerns: [Concern.agriculture],
      lifeParams: {
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 70,
        'safety': 50,
      },
    );
    final society = SocietyState(
      happiness: 65.0,
      mood: 0.4,
      electionCount: 2,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          citizen: citizen,
          societyState: society,
          remainingTurns: 5,
          onOpenPrediction: () => callCount++,
        ),
      ),
    );

    await tester.tap(find.byKey(AppKeys.homePredictionButton));
    expect(callCount, 1);
  });

  testWidgets('onOpenPrediction が null のときタップしても落ちない', (tester) async {
    final citizen = Citizen(
      name: 'テスト太郎',
      job: Job.farmer,
      concerns: [Concern.agriculture],
      lifeParams: {
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 70,
        'safety': 50,
      },
    );
    final society = SocietyState(
      happiness: 65.0,
      mood: 0.4,
      electionCount: 2,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          citizen: citizen,
          societyState: society,
          remainingTurns: 5,
        ),
      ),
    );

    await tester.tap(find.byKey(AppKeys.homePredictionButton));
    await tester.pumpAndSettle();
  });
}
