import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/services/quiz_service.dart';
import 'package:election_game/features/quiz/presentation/quiz_difficulty_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuizDifficultyScreen()),
    );
    await tester.pumpAndSettle();
  }

  group('QuizDifficultyScreen', () {
    testWidgets('タイトルと説明文が表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.quizDifficultyScreen), findsOneWidget);
      expect(find.text('政策・制度クイズ'), findsOneWidget);
      expect(find.byKey(AppKeys.quizDifficultyOption(QuizDifficulty.beginner)),
          findsOneWidget);
      expect(
          find.byKey(AppKeys.quizDifficultyOption(QuizDifficulty.intermediate)),
          findsOneWidget);
      expect(find.byKey(AppKeys.quizDifficultyOption(QuizDifficulty.advanced)),
          findsOneWidget);
      expect(find.byKey(AppKeys.quizDifficultyAll), findsOneWidget);
    });

    testWidgets('難易度ボタンにはサービス集計の件数が併記される', (tester) async {
      await pumpScreen(tester);

      final defaults = QuizService.defaultQuestions();
      int count(QuizDifficulty d) => QuizService.countByDifficulty(defaults, d);
      expect(
        find.text('初級（${count(QuizDifficulty.beginner)}問）'),
        findsOneWidget,
      );
      expect(
        find.text('中級（${count(QuizDifficulty.intermediate)}問）'),
        findsOneWidget,
      );
      expect(
        find.text('上級（${count(QuizDifficulty.advanced)}問）'),
        findsOneWidget,
      );
      expect(find.text('すべて（全問）'), findsOneWidget);
    });

    testWidgets('初級タップでQuizScreenへ遷移し、最初の問題は初級である', (tester) async {
      await pumpScreen(tester);

      await tester.tap(
          find.byKey(AppKeys.quizDifficultyOption(QuizDifficulty.beginner)));
      await tester.pumpAndSettle();

      // クイズ画面に遷移し、難易度バッジに「初級」が出る
      expect(find.byKey(AppKeys.quizDifficultyBadge), findsOneWidget);
      expect(find.text('初級'), findsOneWidget);

      // 進捗の分母は初級の件数と一致する（画面が独自集計していない証拠）
      final beginnerCount = QuizService.countByDifficulty(
        QuizService.defaultQuestions(),
        QuizDifficulty.beginner,
      );
      expect(find.text('問 1 / $beginnerCount'), findsOneWidget);
    });

    testWidgets('「すべて」タップで全問（16問）が出題される', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.quizDifficultyAll));
      await tester.pumpAndSettle();

      expect(
        find.text('問 1 / ${QuizService.defaultQuestions().length}'),
        findsOneWidget,
      );
      // 難易度バッジは表示されない
      expect(find.byKey(AppKeys.quizDifficultyBadge), findsNothing);
    });
  });
}
