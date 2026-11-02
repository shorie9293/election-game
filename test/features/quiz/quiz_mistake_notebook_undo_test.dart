// 復習ノート全消去の Undo（元に戻す）配線の widget 試練。
//
// 参照実装（tsundoku-quest の reading_session_undo_test.dart）と同型。
// InMemoryQuizMistakeRepository を注入して IO を避ける。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/features/quiz/presentation/quiz_mistake_notebook_screen.dart';
import 'package:election_game/features/undo/presentation/undo_snack_bar.dart';

/// save/clear の呼び出し回数を数えるフェイク（二重復元の検出用）。
class CountingQuizMistakeRepository extends InMemoryQuizMistakeRepository {
  CountingQuizMistakeRepository([super.initial]);

  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> save(List<QuizMistakeEntry> entries) async {
    saveCalls++;
    await super.save(entries);
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    await super.clear();
  }
}

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

  Future<void> pumpNotebook(
    WidgetTester tester, {
    required List<QuizMistakeEntry> entries,
    required QuizMistakeRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizMistakeNotebookScreen(
          key: UniqueKey(),
          entriesOverride: entries,
          repository: repository,
          questionsOverride: questions,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// ゴミ箱 → 確認ダイアログ「消去する」までを踏む。
  Future<void> clearAll(WidgetTester tester) async {
    await tester.tap(find.byKey(AppKeys.quizNotebookClearButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.quizNotebookClearConfirmButton));
    await tester.pumpAndSettle();
  }

  /// SnackBar の 5 秒タイマーを流し切る（pending timer を残さない）。
  Future<void> drainSnackBar(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('復習ノート全消去の Undo', () {
    testWidgets('① 消去確認で一覧が空になりリポジトリも空になる', (tester) async {
      final repository = CountingQuizMistakeRepository([
        entry(questionId: 'system_1', wrongCount: 2),
        entry(
          questionId: 'policy_1',
          category: QuizCategory.policy,
          correctIndex: 0,
          wrongCount: 1,
        ),
      ]);
      await pumpNotebook(
        tester,
        entries: repository.entries,
        repository: repository,
      );

      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')),
          findsOneWidget);

      await clearAll(tester);

      // 消去は即時実行（既存挙動は不変）
      expect(find.byKey(AppKeys.quizNotebookEmpty), findsOneWidget);
      expect(repository.entries, isEmpty);
      expect(repository.clearCalls, 1);

      // Undo 導線が出ている
      expect(find.text('復習ノートを消去しました'), findsOneWidget);
      expect(find.byKey(undoActionKey), findsOneWidget);
      expect(find.text('元に戻す'), findsOneWidget);

      await drainSnackBar(tester);
    });

    testWidgets('② 「元に戻す」で同じ questionId 群・同じ内容が復元され保存される', (tester) async {
      final entries = [
        entry(questionId: 'system_1', wrongCount: 3, lastSelectedIndex: 0),
        entry(
          questionId: 'policy_1',
          category: QuizCategory.policy,
          correctIndex: 0,
          wrongCount: 1,
          lastSelectedIndex: 2,
        ),
      ];
      final repository = CountingQuizMistakeRepository(entries);
      await pumpNotebook(
        tester,
        entries: entries,
        repository: repository,
      );

      await clearAll(tester);
      await tester.tap(find.byKey(undoActionKey));
      await tester.pumpAndSettle();

      // リポジトリへ保存され、内容も一致する
      expect(repository.saveCalls, 1);
      expect(
        repository.entries.map((e) => e.questionId).toSet(),
        {'system_1', 'policy_1'},
      );
      expect(repository.entries, entries);

      // 画面にも同じ並び（要復習は誤答回数の多い順）で戻る
      expect(find.byKey(AppKeys.quizNotebookEmpty), findsNothing);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')),
          findsOneWidget);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('policy_1')),
          findsOneWidget);
      expect(find.text('×3'), findsOneWidget);
      expect(find.text('要復習 2 問 ／ 克服済み 0 問'), findsOneWidget);

      await drainSnackBar(tester);
    });

    testWidgets('③ 二度目の Undo では二重復元しない（take は一度きり）', (tester) async {
      final entries = [entry(questionId: 'system_1', wrongCount: 2)];
      final repository = CountingQuizMistakeRepository(entries);
      await pumpNotebook(tester, entries: entries, repository: repository);

      await clearAll(tester);

      // 連打しても復元は一度だけ（take() が消費済みなら null で素通り）
      await tester.tap(find.byKey(undoActionKey));
      await tester.pumpAndSettle();
      expect(repository.saveCalls, 1);
      expect(repository.entries, hasLength(1));

      // 1回目の Undo で SnackBar は閉じ、取り消しアクションは消える
      expect(find.byKey(undoActionKey), findsNothing);

      await drainSnackBar(tester);
      expect(repository.saveCalls, 1);
      expect(repository.entries, hasLength(1));
    });

    testWidgets('④ 空リストでは消去ボタンが出ず、未知 ID でも例外を投げない', (tester) async {
      final repository = CountingQuizMistakeRepository();
      await pumpNotebook(tester, entries: const [], repository: repository);

      expect(find.byKey(AppKeys.quizNotebookEmpty), findsOneWidget);
      expect(find.byKey(AppKeys.quizNotebookClearButton), findsNothing);

      // 問題バンクに無い ID でも描画・消去・復元で落ちない
      final unknown = [entry(questionId: 'unknown_1')];
      final repository2 = CountingQuizMistakeRepository(unknown);
      await pumpNotebook(
        tester,
        entries: unknown,
        repository: repository2,
      );
      expect(find.byKey(AppKeys.quizNotebookEntryCard('unknown_1')),
          findsOneWidget);

      await clearAll(tester);
      expect(repository2.entries, isEmpty);

      await tester.tap(find.byKey(undoActionKey));
      await tester.pumpAndSettle();
      expect(repository2.entries.map((e) => e.questionId), ['unknown_1']);

      await drainSnackBar(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('⑤ 既存の確認ダイアログ経由の挙動が壊れない（やめるで消えない）', (tester) async {
      final repository = CountingQuizMistakeRepository([
        entry(questionId: 'system_1'),
      ]);
      await pumpNotebook(
        tester,
        entries: repository.entries,
        repository: repository,
      );

      await tester.tap(find.byKey(AppKeys.quizNotebookClearButton));
      await tester.pumpAndSettle();
      expect(find.text('復習ノートを消去しますか？'), findsOneWidget);
      // Undo 可能になったため文言を訂正済み（取り消せません、ではない）
      expect(find.textContaining('直後に「元に戻す」で復元できます。'), findsOneWidget);

      await tester.tap(find.text('やめる'));
      await tester.pumpAndSettle();

      expect(repository.clearCalls, 0);
      expect(repository.entries, isNotEmpty);
      expect(find.byKey(AppKeys.quizNotebookEntryCard('system_1')),
          findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
