import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ホーム AppBar のアプリロック項目から設定画面へ遷移する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
          societyState: SocietyState.initial(),
          remainingTurns: 5,
        ),
      ),
    );

    expect(find.byKey(AppKeys.appLockSettingsEntry), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.appLockSettingsEntry));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.appLockSettingsScreen), findsOneWidget);
    expect(find.byKey(AppKeys.appLockSettingsTitle), findsOneWidget);
  });
}
