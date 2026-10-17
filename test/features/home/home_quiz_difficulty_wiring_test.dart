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

  Future<void> pumpHome(WidgetTester tester) async {
    // ボタンが縦に長く並ぶため既定ビューポートでは下方が遅延描画される
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
          societyState: SocietyState.initial(),
          remainingTurns: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('HomeScreen クイズ難易度選択導線', () {
    testWidgets('クイズボタンを押すと難易度選択画面へ遷移する', (tester) async {
      await pumpHome(tester);

      expect(find.byKey(AppKeys.homeQuizButton), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.homeQuizButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizDifficultyScreen), findsOneWidget);
    });
  });
}
