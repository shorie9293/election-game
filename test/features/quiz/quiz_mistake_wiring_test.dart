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

  /// 過去の固定時刻（端末時計・CIのタイムゾーンに依存しない）。
  /// 実時計（DateTime.now()）と比較される試練では必ず「十分に過去」を使え
  /// —— CI は UTC で走るため、固定時刻を未来に置くと時限爆弾になる。
  final base = DateTime.utc(2020, 1, 1);

  QuizMistakeEntry entry({
    required String questionId,
    QuizCategory category = QuizCategory.system,
    int correctIndex = 2,
    int wrongCount = 1,
    int? lastSelectedIndex = 1,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: category,
      correctIndex: correctIndex,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex,
      lastWrongAt: base,
    );
  }

  /// クイズを最後まで解く（[choices] のインデックス列で回答）。
  Future<void> playQuiz(WidgetTester tester, List<int> choices) async {
    for (var i = 0; i < choices.length; i++) {
      await tester.tap(find.byKey(AppKeys.quizChoice(choices[i])));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuizScreen → 誤答復習ノートの配線', () {
    testWidgets('誤答がリポジトリへ記録される', (tester) async {
      final repository = InMemoryQuizMistakeRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: questions, mistakeRepository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // system_1 を誤答（正解は 2）・policy_1 を誤答（正解は 0）
      await playQuiz(tester, [0, 1]);

      final saved = repository.entries;
      expect(saved.map((e) => e.questionId).toSet(), {'system_1', 'policy_1'});
      expect(saved.every((e) => e.wrongCount == 1), isTrue);
      expect(saved.every((e) => e.isPending), isTrue);
    });

    testWidgets('全問正解なら復習ノートに何も記録されない', (tester) async {
      final repository = InMemoryQuizMistakeRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: questions, mistakeRepository: repository),
        ),
      );
      await tester.pumpAndSettle();

      await playQuiz(tester, [2, 0]);

      expect(repository.entries, isEmpty);
    });

    testWidgets('同じ問題に再度誤答すると誤答回数が加算される', (tester) async {
      final repository = InMemoryQuizMistakeRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: questions, mistakeRepository: repository),
        ),
      );
      await tester.pumpAndSettle();
      await playQuiz(tester, [0, 1]);

      // もう一度挑戦して同じ選択
      await tester.tap(find.byKey(AppKeys.quizRetryButton));
      await tester.pumpAndSettle();
      await playQuiz(tester, [0, 1]);

      final system1 =
          repository.entries.firstWhere((e) => e.questionId == 'system_1');
      expect(system1.wrongCount, 2);
    });

    testWidgets('保存失敗してもクイズの採点結果は表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(
            questions: questions,
            mistakeRepository: _ThrowingQuizMistakeRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await playQuiz(tester, [2, 0]);

      expect(find.byKey(AppKeys.quizResultScore), findsOneWidget);
      expect(find.text('2 / 2 問正解（100%）'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('親探針：復習ノート ⇄ クイズの合成', () {
    testWidgets('再挑戦で正解するとノートが克服済みへ更新される', (tester) async {
      final repository = InMemoryQuizMistakeRepository([
        entry(questionId: 'system_1'),
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

      expect(find.text('要復習 1 問 ／ 克服済み 0 問'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizNotebookRetryButton));
      await tester.pumpAndSettle();

      // 復習では1問だけ出題される
      expect(find.text('問 1 / 1'), findsOneWidget);
      await playQuiz(tester, [2]); // 正解
      await tester.tap(find.byKey(AppKeys.quizCloseButton));
      await tester.pumpAndSettle();

      // ノートへ戻ると克服済みへ移動している（画面→リポジトリ→再表示の合成）
      expect(find.text('要復習 0 問 ／ 克服済み 1 問'), findsOneWidget);
      expect(find.byKey(AppKeys.quizNotebookMasteredSection), findsOneWidget);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')), findsNothing);
      expect(repository.entries.single.isMastered, isTrue);
    });

    testWidgets('再挑戦で誤答すると誤答回数が増える', (tester) async {
      final repository = InMemoryQuizMistakeRepository([
        entry(questionId: 'system_1', wrongCount: 2),
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
      expect(find.text('×2'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.quizNotebookRetryButton));
      await tester.pumpAndSettle();
      await playQuiz(tester, [0]); // 正解は 2 なので誤答
      await tester.tap(find.byKey(AppKeys.quizCloseButton));
      await tester.pumpAndSettle();

      expect(find.text('×3'), findsOneWidget);
    });

    testWidgets('絞り込み中の再挑戦は絞り込み内だけ克服される', (tester) async {
      final repository = InMemoryQuizMistakeRepository([
        entry(questionId: 'system_1'),
        entry(
          questionId: 'policy_1',
          category: QuizCategory.policy,
          correctIndex: 0,
          lastSelectedIndex: 1,
        ),
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

      await tester.tap(find.byKey(AppKeys.quizNotebookCategoryChip('政策')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNotebookRetryButton));
      await tester.pumpAndSettle();
      await playQuiz(tester, [0]); // policy_1 正解
      await tester.tap(find.byKey(AppKeys.quizCloseButton));
      await tester.pumpAndSettle();

      final policy1 =
          repository.entries.firstWhere((e) => e.questionId == 'policy_1');
      final system1 =
          repository.entries.firstWhere((e) => e.questionId == 'system_1');
      expect(policy1.isMastered, isTrue);
      expect(system1.isPending, isTrue);
    });
  });
}

/// 読み書きが必ず失敗するリポジトリ（異常系の合成検証用）。
class _ThrowingQuizMistakeRepository implements QuizMistakeRepository {
  @override
  Future<List<QuizMistakeEntry>> load() async => throw Exception('load failed');

  @override
  Future<void> save(List<QuizMistakeEntry> entries) async =>
      throw Exception('save failed');

  @override
  Future<void> clear() async => throw Exception('clear failed');
}
