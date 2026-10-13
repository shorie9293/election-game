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

  group('HomeScreen 間違い復習ノート導線', () {
    testWidgets('間違い復習ノートのボタンが表示される', (tester) async {
      await pumpHome(tester);

      expect(find.byKey(AppKeys.homeQuizNotebookButton), findsOneWidget);
      expect(find.text('間違い復習ノート'), findsOneWidget);
    });

    testWidgets('ボタンを押すと間違い復習ノート画面へ遷移する', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byKey(AppKeys.homeQuizNotebookButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizNotebookScreen), findsOneWidget);
      // 記録が無いので空状態が表示される
      expect(find.byKey(AppKeys.quizNotebookEmpty), findsOneWidget);
    });
  });
}
