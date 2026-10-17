import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/about/presentation/about_app_keys.dart';
import 'package:election_game/features/about/presentation/about_screen.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('ホームのAppBarからアプリについて画面へ遷移できる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          citizen: Citizen.initial(Job.farmer),
          societyState: SocietyState.initial(),
          remainingTurns: 10,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(AboutAppKeys.homeAboutButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(AboutAppKeys.homeAboutButton));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.byKey(AboutAppKeys.aboutScreen), findsOneWidget);
  });
}
