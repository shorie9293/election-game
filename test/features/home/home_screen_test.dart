import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('メイン画面に生活パラメータが表示される', (tester) async {
      final citizen = Citizen.initial(Job.farmer).copyWith(name: '農家太郎');
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: citizen,
            societyState: SocietyState.initial(),
            remainingTurns: 10,
          ),
        ),
      );

      expect(find.byKey(const Key('home_title')), findsOneWidget);
      expect(find.byKey(const Key('home_life_params')), findsOneWidget);
      expect(find.byKey(const Key('home_countdown')), findsOneWidget);
      expect(find.text('農家太郎'), findsOneWidget);
    });

    testWidgets('次回選挙までのカウントダウンが表示される', (tester) async {
      final citizen = Citizen.initial(Job.farmer).copyWith(name: 'テスト');
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: citizen,
            societyState: SocietyState.initial(),
            remainingTurns: 10,
          ),
        ),
      );

      expect(find.text('次回選挙まで'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('選挙に行くボタンが表示される', (tester) async {
      final citizen = Citizen.initial(Job.farmer).copyWith(name: 'テスト');
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: citizen,
            societyState: SocietyState.initial(),
            remainingTurns: 0,
          ),
        ),
      );

      expect(find.byKey(const Key('home_election_button')), findsOneWidget);
    });

    testWidgets('社会ムードが表示される', (tester) async {
      final citizen = Citizen.initial(Job.farmer).copyWith(name: 'テスト');
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: citizen,
            societyState: SocietyState.initial(),
            remainingTurns: 5,
          ),
        ),
      );

      expect(find.byKey(const Key('home_society_mood')), findsOneWidget);
    });
  });
}
