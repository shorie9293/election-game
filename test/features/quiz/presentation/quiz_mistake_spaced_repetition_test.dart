import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/features/quiz/presentation/quiz_mistake_notebook_screen.dart';
import 'package:election_game/features/quiz/presentation/quiz_screen.dart';

void main() {
  final now = DateTime(2026, 11, 4, 9, 0);

  final questions = <QuizQuestion>[
    QuizQuestion(
      id: 'q1',
      category: QuizCategory.system,
      question: '問題1',
      choices: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: '解説1',
    ),
    QuizQuestion(
      id: 'q2',
      category: QuizCategory.system,
      question: '問題2',
      choices: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: '解説2',
    ),
    QuizQuestion(
      id: 'q3',
      category: QuizCategory.system,
      question: '問題3',
      choices: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: '解説3',
    ),
  ];

  QuizMistakeEntry entry({
    required String questionId,
    required DateTime dueAt,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: QuizCategory.system,
      correctIndex: 0,
      wrongCount: 1,
      lastSelectedIndex: 1,
      lastWrongAt: now.subtract(const Duration(days: 2)),
      dueAt: dueAt,
    );
  }

  Widget buildScreen({
    required List<QuizMistakeEntry> entries,
    DateTime? nowOverride,
    int dailyReviewLimit = 10,
    Key? key,
  }) {
    return MaterialApp(
      home: QuizMistakeNotebookScreen(
        key: key,
        entriesOverride: entries,
        repository: InMemoryQuizMistakeRepository(),
        questionsOverride: questions,
        nowOverride: () => nowOverride ?? now,
        dailyReviewLimit: dailyReviewLimit,
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('期限到来0件なら今日の復習ボタンは存在しない', (tester) async {
    final entries = [
      entry(questionId: 'q1', dueAt: now.add(const Duration(days: 1))),
    ];
    await tester.pumpWidget(buildScreen(entries: entries));
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.quizNotebookTodayReviewButton), findsNothing);
  });

  testWidgets('期限到来2件・未到来1件なら今日の復習 2問と表示', (tester) async {
    final entries = [
      entry(questionId: 'q1', dueAt: now),
      entry(questionId: 'q2', dueAt: now.subtract(const Duration(days: 1))),
      entry(questionId: 'q3', dueAt: now.add(const Duration(days: 1))),
    ];
    await tester.pumpWidget(buildScreen(entries: entries));
    await tester.pumpAndSettle();
    expect(find.text('今日の復習 2問'), findsOneWidget);
    expect(find.byKey(AppKeys.quizNotebookTodayReviewButton), findsOneWidget);
  });

  testWidgets('今日の復習をタップすると2問だけ出題される', (tester) async {
    final entries = [
      entry(questionId: 'q1', dueAt: now),
      entry(questionId: 'q2', dueAt: now.subtract(const Duration(days: 1))),
      entry(questionId: 'q3', dueAt: now.add(const Duration(days: 1))),
    ];
    await tester.pumpWidget(buildScreen(entries: entries));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.quizNotebookTodayReviewButton));
    await tester.pumpAndSettle();
    final quizScreen = tester.widget<QuizScreen>(find.byType(QuizScreen));
    expect(quizScreen.questions!.length, 2);
  });

  testWidgets('日付跨ぎ: 同じエントリで now を dueAt 翌日にすると0件→翌日は1件', (tester) async {
    final entries = [
      entry(questionId: 'q1', dueAt: now.add(const Duration(days: 1))),
    ];
    await tester.pumpWidget(buildScreen(entries: entries));
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.quizNotebookTodayReviewButton), findsNothing);

    final nextDay = now.add(const Duration(days: 2));
    await tester.pumpWidget(
      buildScreen(
        key: const ValueKey('next-day'),
        entries: entries,
        nowOverride: nextDay,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.quizNotebookTodayReviewButton), findsOneWidget);
    expect(find.text('今日の復習 1問'), findsOneWidget);
  });

  testWidgets('行に次回 M/d が出る', (tester) async {
    final entries = [
      entry(questionId: 'q1', dueAt: DateTime(2026, 11, 6)),
    ];
    await tester.pumpWidget(buildScreen(entries: entries));
    await tester.pumpAndSettle();
    expect(find.text('次回 11/6'), findsOneWidget);
    expect(find.byKey(AppKeys.quizNotebookEntryDueLabel('q1')), findsOneWidget);
  });

  testWidgets('dailyReviewLimit=1 なら1問だけ出題', (tester) async {
    final entries = [
      entry(questionId: 'q1', dueAt: now),
      entry(questionId: 'q2', dueAt: now.subtract(const Duration(days: 1))),
      entry(questionId: 'q3', dueAt: now.add(const Duration(days: 1))),
    ];
    await tester.pumpWidget(buildScreen(entries: entries, dailyReviewLimit: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.quizNotebookTodayReviewButton));
    await tester.pumpAndSettle();
    final quizScreen = tester.widget<QuizScreen>(find.byType(QuizScreen));
    expect(quizScreen.questions!.length, 1);
  });
}
