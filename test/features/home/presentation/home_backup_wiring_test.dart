import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/backup/presentation/game_data_backup_screen.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildHome() {
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
    return MaterialApp(
      home: HomeScreen(
        citizen: citizen,
        societyState: society,
        remainingTurns: 5,
      ),
    );
  }

  testWidgets('homeBackupButton が AppBar actions に存在する', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildHome());

    expect(find.byKey(AppKeys.homeBackupButton), findsOneWidget);
  });

  testWidgets('homeBackupButton をタップすると backupScreen に遷移する', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildHome());

    await tester.tap(find.byKey(AppKeys.homeBackupButton));
    await tester.pumpAndSettle();

    // GameDataBackupScreen が push され、その Scaffold が表示されている
    expect(find.byType(GameDataBackupScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w.key == AppKeys.backupScreen && w is Scaffold,
      ),
      findsOneWidget,
    );
  });
}