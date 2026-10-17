// 親探針: クイズ難易度機能の「合成の不変条件」を撃つ試練。
//
// 眷属は個別の振る舞いしか撃たないため、画面→サービス→出題の合成、
// および画面が独自集計していないことを親が独立に検証する。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/services/quiz_service.dart';
import 'package:election_game/features/quiz/presentation/quiz_difficulty_screen.dart';
import 'package:election_game/features/quiz/presentation/quiz_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpStart(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuizDifficultyScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('探針1: 選択画面の件数ラベルがサービス算出値と完全一致する', (tester) async {
    await pumpStart(tester);
    final bank = QuizService.defaultQuestions();

    for (final d in QuizDifficulty.values) {
      final count = QuizService.countByDifficulty(bank, d);
      expect(count, greaterThan(0));
      expect(
        find.descendant(
          of: find.byKey(AppKeys.quizDifficultyOption(d)),
          matching: find.text('${d.label}（$count問）'),
        ),
        findsOneWidget,
        reason: '画面が独自集計しているか、サービス値とずれている',
      );
    }
  });

  testWidgets('探針2: 難易度選択→出題の分母と1問目の難易度がサービスと一致する', (tester) async {
    final bank = QuizService.defaultQuestions();
    final limit = QuizService.countByDifficulty(
      bank,
      QuizDifficulty.advanced,
    );

    await pumpStart(tester);
    await tester.tap(find.byKey(AppKeys.quizDifficultyOption(QuizDifficulty.advanced)));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.quizDifficultyBadge), findsOneWidget);
    expect(find.text('問 1 / $limit'), findsOneWidget);

    // 画面に出ている問題文が、その難易度の問題集合に実在すること
    final shown = tester.widget<Text>(find.byKey(AppKeys.quizQuestionText)).data;
    final pool = QuizService.questionsByDifficulty(
      bank,
      QuizDifficulty.advanced,
    ).map((q) => q.question);
    expect(pool, contains(shown));
  });

  testWidgets('探針3: 全問解答後の結果画面に難易度が出て、再挑戦でも同じ分母を保つ', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuizScreen(difficulty: QuizDifficulty.beginner)),
    );
    await tester.pumpAndSettle();

    final total = QuizService.countByDifficulty(
      QuizService.defaultQuestions(),
      QuizDifficulty.beginner,
    );

    for (var i = 0; i < total; i++) {
      expect(find.text('問 ${i + 1} / $total'), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.quizChoice(0)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(AppKeys.quizResultView), findsOneWidget);
    expect(find.text('難易度: 初級'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.quizRetryButton));
    await tester.pumpAndSettle();
    expect(find.text('問 1 / $total'), findsOneWidget,
        reason: '再挑戦で難易度が失われ全問に戻っている');
    expect(find.byKey(AppKeys.quizDifficultyBadge), findsOneWidget);
  });

  testWidgets('探針4: 「すべて（全問）」は既定バンク全件を出題する', (tester) async {
    final total = QuizService.defaultQuestions().length;
    await pumpStart(tester);
    await tester.tap(find.byKey(AppKeys.quizDifficultyAll));
    await tester.pumpAndSettle();

    expect(find.text('問 1 / $total'), findsOneWidget);
    expect(find.byKey(AppKeys.quizDifficultyBadge), findsNothing);
  });
}
