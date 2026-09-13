import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_repository.dart';
import 'package:election_game/features/quiz/presentation/quiz_screen.dart';

void main() {
  final questions = [
    QuizQuestion(
      id: 'q1',
      category: QuizCategory.system,
      question: '衆議院議員の任期は？',
      choices: const ['2年', '4年', '6年'],
      correctIndex: 1,
      explanation: '衆議院議員の任期は4年です。',
    ),
    QuizQuestion(
      id: 'q2',
      category: QuizCategory.policy,
      question: '奨学金の拡充はどの政策分野？',
      choices: const ['教育政策', '農業政策'],
      correctIndex: 0,
      explanation: '奨学金は教育政策の代表例です。',
    ),
  ];

  Future<void> pumpQuiz(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          repository: const QuizRepository(),
          questions: questions,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuizScreen', () {
    testWidgets('最初の問題・進捗・カテゴリが表示される', (tester) async {
      await pumpQuiz(tester);

      expect(find.byKey(AppKeys.quizProgress), findsOneWidget);
      expect(find.text('問 1 / 2'), findsOneWidget);
      expect(find.byKey(AppKeys.quizQuestionText), findsOneWidget);
      expect(find.text('衆議院議員の任期は？'), findsOneWidget);
      expect(find.byKey(AppKeys.quizCategory), findsOneWidget);
      expect(find.byKey(AppKeys.quizChoice(0)), findsOneWidget);
      expect(find.byKey(AppKeys.quizChoice(2)), findsOneWidget);
    });

    testWidgets('正解を選ぶと「正解！」と解説が出る', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizFeedback), findsOneWidget);
      expect(find.text('正解！'), findsOneWidget);
      expect(find.byKey(AppKeys.quizExplanation), findsOneWidget);
      expect(find.text('衆議院議員の任期は4年です。'), findsOneWidget);
      expect(find.byKey(AppKeys.quizNextButton), findsOneWidget);
    });

    testWidgets('不正解を選ぶと「不正解…」と解説が出る', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(0)));
      await tester.pumpAndSettle();

      expect(find.text('不正解…'), findsOneWidget);
      expect(find.text('衆議院議員の任期は4年です。'), findsOneWidget);
    });

    testWidgets('回答後は同じ問題を選び直せない（再タップは無視）', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(0)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();

      // 一度答えた後は不正解表示のまま変わらない
      expect(find.text('不正解…'), findsOneWidget);
      expect(find.text('正解！'), findsNothing);
    });

    testWidgets('次の問題へ進むと進捗が更新される', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      expect(find.text('問 2 / 2'), findsOneWidget);
      expect(find.text('奨学金の拡充はどの政策分野？'), findsOneWidget);
      // 最終問題ではボタンが「結果を見る」になる
      expect(find.text('結果を見る'), findsNothing); // 未回答時は非表示
    });

    testWidgets('全問回答後に結果ビュー・正答数・ラベル・合格判定が出る', (tester) async {
      await pumpQuiz(tester);

      // 1問目: 正解
      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      // 2問目: 不正解
      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      expect(find.text('結果を見る'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizResultView), findsOneWidget);
      expect(find.byKey(AppKeys.quizResultScore), findsOneWidget);
      expect(find.text('1 / 2 問正解（50%）'), findsOneWidget);
      expect(find.byKey(AppKeys.quizResultRank), findsOneWidget);
      expect(find.text('もう一息'), findsOneWidget);
      expect(find.byKey(AppKeys.quizResultBadge), findsOneWidget);
      expect(find.byKey(AppKeys.quizBestScore), findsOneWidget);
    });

    testWidgets('振り返りに間違えた問題と解説が出る', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizResultMissed), findsOneWidget);
      expect(find.text('・奨学金の拡充はどの政策分野？'), findsOneWidget);
      expect(find.text('奨学金は教育政策の代表例です。'), findsOneWidget);
    });

    testWidgets('全問正解なら振り返りは称賛メッセージになる', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.quizChoice(0)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      expect(find.text('選挙マスター'), findsOneWidget);
      expect(find.text('全問正解です。素晴らしい理解度です！'), findsOneWidget);
      expect(find.text('合格ライン達成 🎉'), findsOneWidget);
    });

    testWidgets('もう一度挑戦で最初の問題へ戻る', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizChoice(0)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizResultView), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizRetryButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizResultView), findsNothing);
      expect(find.text('問 1 / 2'), findsOneWidget);
      expect(find.text('衆議院議員の任期は？'), findsOneWidget);
    });

    testWidgets('結果はリポジトリに保存され自己ベストが表示される', (tester) async {
      SharedPreferences.setMockInitialValues({
        QuizRepository.bestCorrectKey: 1,
        QuizRepository.bestTotalKey: 2,
        QuizRepository.attemptsKey: 3,
      });
      await pumpQuiz(tester);

      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizChoice(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();

      // 1/2 は同点なのでベストは維持される
      expect(find.textContaining('自己ベスト: 1 / 2'), findsOneWidget);

      // リポジトリには挑戦回数が記録される
      final attempts = await const QuizRepository().loadAttempts();
      expect(attempts, 4);
    });
  });
}
