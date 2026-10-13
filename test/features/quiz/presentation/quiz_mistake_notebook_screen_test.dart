import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/features/quiz/presentation/quiz_mistake_notebook_screen.dart';

void main() {
  final now = DateTime(2026, 10, 13, 10, 0);

  final questions = <QuizQuestion>[
    QuizQuestion(
      id: 'system_1',
      category: QuizCategory.system,
      question: '衆議院議員の任期は何年か？',
      choices: const ['2年', '3年', '4年', '6年'],
      correctIndex: 2,
      explanation: '衆議院議員の任期は4年です。',
    ),
    QuizQuestion(
      id: 'policy_1',
      category: QuizCategory.policy,
      question: '奨学金の拡充は、どの政策分野か？',
      choices: const ['教育政策', '農業政策', '治安政策', '雇用政策'],
      correctIndex: 0,
      explanation: '奨学金・少人数学級などは教育政策の代表例です。',
    ),
  ];

  QuizMistakeEntry entry({
    required String questionId,
    QuizCategory category = QuizCategory.system,
    int correctIndex = 2,
    int wrongCount = 1,
    int? lastSelectedIndex = 1,
    DateTime? lastWrongAt,
    DateTime? masteredAt,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: category,
      correctIndex: correctIndex,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex,
      lastWrongAt: lastWrongAt ?? now,
      masteredAt: masteredAt,
    );
  }

  Future<void> pumpNotebook(
    WidgetTester tester, {
    required List<QuizMistakeEntry> entries,
    QuizMistakeRepository? repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizMistakeNotebookScreen(
          entriesOverride: entries,
          repository: repository ?? InMemoryQuizMistakeRepository(entries),
          questionsOverride: questions,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuizMistakeNotebookScreen 表示', () {
    testWidgets('空なら空状態を表示する', (tester) async {
      await pumpNotebook(tester, entries: const []);

      expect(find.byKey(AppKeys.quizNotebookEmpty), findsOneWidget);
      expect(find.text('まだ誤答の記録がありません'), findsOneWidget);
      expect(find.byKey(AppKeys.quizNotebookSummary), findsNothing);
    });

    testWidgets('サマリーに要復習・克服済み・のべ誤答が出る', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(questionId: 'system_1', wrongCount: 3),
        entry(
          questionId: 'policy_1',
          category: QuizCategory.policy,
          correctIndex: 0,
          wrongCount: 1,
          masteredAt: now.add(const Duration(hours: 1)),
        ),
      ]);

      expect(find.byKey(AppKeys.quizNotebookSummary), findsOneWidget);
      expect(find.text('要復習 1 問 ／ 克服済み 1 問'), findsOneWidget);
      expect(find.text('のべ誤答 4 回'), findsOneWidget);
    });

    testWidgets('誤答カードに問題文・誤答回数・解答・解説が出る', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(questionId: 'system_1', wrongCount: 2),
      ]);

      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsOneWidget);
      expect(find.text('衆議院議員の任期は何年か？'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('あなたの解答: 3年'), findsOneWidget);
      expect(find.text('正解: 4年'), findsOneWidget);
      expect(find.text('衆議院議員の任期は4年です。'), findsOneWidget);
    });

    testWidgets('未回答の誤答は「未回答」と表示される', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(questionId: 'system_1', lastSelectedIndex: null),
      ]);

      expect(find.text('あなたの解答: 未回答'), findsOneWidget);
    });

    testWidgets('克服済みセクションに克服した問題が並ぶ', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(
          questionId: 'system_1',
          masteredAt: now.add(const Duration(hours: 1)),
        ),
      ]);

      expect(find.byKey(AppKeys.quizNotebookMasteredSection), findsOneWidget);
      expect(find.text('克服済み（1 問）'), findsOneWidget);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsNothing);
    });

    testWidgets('誤答回数の多い順に並ぶ', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(questionId: 'policy_1', category: QuizCategory.policy, correctIndex: 0, wrongCount: 1),
        entry(questionId: 'system_1', wrongCount: 5),
      ]);

      final systemY =
          tester.getTopLeft(find.byKey(AppKeys.quizNotebookEntryCard('system_1'))).dy;
      final policyY =
          tester.getTopLeft(find.byKey(AppKeys.quizNotebookEntryCard('policy_1'))).dy;
      expect(systemY, lessThan(policyY));
    });
  });

  group('QuizMistakeNotebookScreen 絞り込み', () {
    testWidgets('カテゴリチップで絞り込める', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(questionId: 'system_1'),
        entry(questionId: 'policy_1', category: QuizCategory.policy, correctIndex: 0),
      ]);

      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsOneWidget);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('policy_1')), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizNotebookCategoryChip('政策')));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsNothing);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('policy_1')), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizNotebookCategoryChip('すべて')));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsOneWidget);
    });

    testWidgets('絞り込み結果が空なら案内文を表示し再挑戦は無効', (tester) async {
      await pumpNotebook(tester, entries: [entry(questionId: 'system_1')]);

      await tester.tap(find.byKey(AppKeys.quizNotebookCategoryChip('政策')));
      await tester.pumpAndSettle();

      expect(find.text('この絞り込みに要復習の問題はありません。'), findsOneWidget);
      expect(find.text('要復習 0 問に再挑戦'), findsOneWidget);
    });
  });

  group('QuizMistakeNotebookScreen 再挑戦', () {
    testWidgets('再挑戦ボタンで未克服の問題だけが出題される', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(questionId: 'system_1'),
      ]);

      expect(find.text('要復習 1 問に再挑戦'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizNotebookRetryButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizQuestionText), findsOneWidget);
      expect(find.text('衆議院議員の任期は何年か？'), findsOneWidget);
      // 復習ノートに無い問題は出題されない
      expect(find.text('奨学金の拡充は、どの政策分野か？'), findsNothing);
    });

    testWidgets('絞り込み中の再挑戦は絞り込み内の問題のみ出題される', (tester) async {
      await pumpNotebook(tester, entries: [
        entry(questionId: 'system_1'),
        entry(questionId: 'policy_1', category: QuizCategory.policy, correctIndex: 0),
      ]);

      await tester.tap(find.byKey(AppKeys.quizNotebookCategoryChip('政策')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNotebookRetryButton));
      await tester.pumpAndSettle();

      expect(find.text('奨学金の拡充は、どの政策分野か？'), findsOneWidget);
      expect(find.text('問 1 / 1'), findsOneWidget);
    });
  });

  group('QuizMistakeNotebookScreen 消去', () {
    testWidgets('確認ダイアログののちリポジトリが消去され空状態になる', (tester) async {
      final repository = InMemoryQuizMistakeRepository([entry(questionId: 'system_1')]);
      await pumpNotebook(
        tester,
        entries: [entry(questionId: 'system_1')],
        repository: repository,
      );

      await tester.tap(find.byKey(AppKeys.quizNotebookClearButton));
      await tester.pumpAndSettle();
      expect(find.text('復習ノートを消去しますか？'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizNotebookClearConfirmButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizNotebookEmpty), findsOneWidget);
      expect(repository.entries, isEmpty);
    });

    testWidgets('やめるを選ぶと消去されない', (tester) async {
      final repository = InMemoryQuizMistakeRepository([entry(questionId: 'system_1')]);
      await pumpNotebook(
        tester,
        entries: [entry(questionId: 'system_1')],
        repository: repository,
      );

      await tester.tap(find.byKey(AppKeys.quizNotebookClearButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('やめる'));
      await tester.pumpAndSettle();

      expect(repository.entries, isNotEmpty);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsOneWidget);
    });
  });

  group('QuizMistakeNotebookScreen リポジトリ読込', () {
    testWidgets('override なしならリポジトリから読み込む', (tester) async {
      final repository = InMemoryQuizMistakeRepository([
        entry(questionId: 'system_1', wrongCount: 4),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: QuizMistakeNotebookScreen(
            repository: repository,
            questionsOverride: questions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsOneWidget);
      expect(find.text('×4'), findsOneWidget);
    });
  });
}
