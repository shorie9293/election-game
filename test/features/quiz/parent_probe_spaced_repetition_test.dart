import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/models/quiz_result.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/domain/services/quiz_mistake_service.dart';
import 'package:election_game/domain/services/spaced_repetition_policy.dart';

/// 親探針（イシコリドメ）: 層をまたぐ不変条件を撃つ。
///
/// 眷属は個別の関数・画面しか撃たないため、ここでは
/// 「採点記録 → 期限計算 → 永続化往復 → 出題対象」の合成を検証する。
void main() {
  final questions = <QuizQuestion>[
    QuizQuestion(
      id: 'probe_1',
      category: QuizCategory.system,
      question: '探針問題1',
      choices: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: '解説1',
    ),
    QuizQuestion(
      id: 'probe_2',
      category: QuizCategory.policy,
      question: '探針問題2',
      choices: const ['A', 'B', 'C', 'D'],
      correctIndex: 1,
      explanation: '解説2',
    ),
  ];

  QuizResult resultOf(List<int?> answers, {required List<QuizQuestion> qs}) {
    return QuizResult(
      answers: answers,
      correctIndexes: [for (final q in qs) q.correctIndex],
    );
  }

  test('探針① 誤答は翌日が期限・当日は出題対象外', () {
    final now = DateTime(2026, 11, 4, 9, 0);
    final updated = QuizMistakeService.record(
      const [],
      questions,
      resultOf([3, 0], qs: questions),
      now: now,
    );

    expect(updated.length, 2);
    for (final e in updated) {
      expect(e.reviewIntervalDays, 1);
      expect(e.dueAt, now.add(const Duration(days: 1)));
    }
    // 当日は 0 件、翌日は 2 件。
    expect(SpacedRepetitionPolicy.countDue(updated, now), 0);
    expect(
      SpacedRepetitionPolicy.countDue(
        updated,
        now.add(const Duration(days: 1)),
      ),
      2,
    );
  });

  test('探針② 期限どおりに正解を重ねると間隔が 1→3→7→14→30 と伸びる', () {
    var now = DateTime(2026, 1, 1, 12, 0);
    final wrong = QuizMistakeService.record(
      const [],
      [questions.first],
      resultOf([3], qs: [questions.first]),
      now: now,
    ).single;
    expect(wrong.reviewIntervalDays, 1);

    final seen = <int>[];
    var entries = [wrong];
    for (var i = 0; i < 5; i++) {
      // 期限到来の瞬間に再確認する（期限前の正解は期限を動かさない仕様）。
      final dueAt = entries.single.dueAt;
      now = dueAt.add(const Duration(minutes: 1));
      entries = QuizMistakeService.record(
        entries,
        [questions.first],
        resultOf([0], qs: [questions.first]),
        now: now,
      );
      seen.add(entries.single.reviewIntervalDays);
      // 期限は「正解した時刻 + 間隔日数」に一致する。
      expect(
        entries.single.dueAt,
        now.add(Duration(days: entries.single.reviewIntervalDays)),
      );
      expect(entries.single.isMastered, isTrue);
    }
    expect(seen, [3, 7, 14, 30, 30]);
  });

  test('探針②-b 期限前の正解は期限を先延ばしにしない', () {
    final now = DateTime(2026, 2, 1, 9, 0);
    final wrong = QuizMistakeService.record(
      const [],
      [questions.first],
      resultOf([3], qs: [questions.first]),
      now: now,
    );
    final justMastered = QuizMistakeService.record(
      wrong,
      [questions.first],
      resultOf([0], qs: [questions.first]),
      now: now.add(const Duration(hours: 1)),
    ).single;
    final dueBefore = justMastered.dueAt;

    // 期限内に何度正解しても期限・間隔は動かない。
    final again = QuizMistakeService.record(
      [justMastered],
      [questions.first],
      resultOf([0], qs: [questions.first]),
      now: now.add(const Duration(hours: 2)),
    ).single;
    expect(again.dueAt, dueBefore);
    expect(again.reviewIntervalDays, justMastered.reviewIntervalDays);
  });

  test('探針③ 克服済みでも期限が来たら再確認の出題対象に戻る', () {
    final now = DateTime(2026, 3, 1, 8, 0);
    final wrong = QuizMistakeService.record(
      const [],
      [questions.first],
      resultOf([3], qs: [questions.first]),
      now: now,
    );
    final mastered = QuizMistakeService.record(
      wrong,
      [questions.first],
      resultOf([0], qs: [questions.first]),
      now: now.add(const Duration(days: 1)),
    ).single;

    expect(mastered.isMastered, isTrue);
    expect(SpacedRepetitionPolicy.countDue([mastered], now), 0);
    expect(
      SpacedRepetitionPolicy.countDue(
        [mastered],
        mastered.dueAt.add(const Duration(minutes: 1)),
      ),
      1,
    );
  });

  test('探針④ 新フィールドは JSON 往復・リポジトリ往復で失われない', () async {
    final now = DateTime(2026, 5, 5, 7, 30);
    final entries = QuizMistakeService.record(
      const [],
      questions,
      resultOf([3, 3], qs: questions),
      now: now,
    );

    final repo = InMemoryQuizMistakeRepository();
    await repo.save(entries);
    final loaded = await repo.load();

    expect(loaded.length, entries.length);
    for (var i = 0; i < entries.length; i++) {
      expect(loaded[i].dueAt, entries[i].dueAt);
      expect(loaded[i].reviewIntervalDays, entries[i].reviewIntervalDays);
    }

    // 旧形式 JSON（dueAt / reviewIntervalDays 欠落）もクラッシュせず読める。
    final legacy = QuizMistakeEntry.fromJson({
      'questionId': 'legacy_1',
      'category': 'system',
      'correctIndex': 0,
      'wrongCount': 2,
      'lastSelectedIndex': 1,
      'lastWrongAt': DateTime(2026, 4, 1, 10).toIso8601String(),
      'masteredAt': null,
    });
    expect(legacy.dueAt, legacy.lastWrongAt);
    expect(legacy.reviewIntervalDays, 0);
    expect(legacy.toJson()['dueAt'], isA<String>());
  });

  test('探針⑤ capDue は期限昇順の先頭から上限件数だけ切り、入力を壊さない', () {
    final now = DateTime(2026, 6, 1, 0, 0);
    QuizMistakeEntry at(int daysAgo) => QuizMistakeEntry(
          questionId: 'p$daysAgo',
          category: QuizCategory.system,
          correctIndex: 0,
          wrongCount: 1,
          lastSelectedIndex: 1,
          lastWrongAt: now.subtract(Duration(days: daysAgo + 1)),
          dueAt: now.subtract(Duration(days: daysAgo)),
        );
    final input = [at(1), at(5), at(2), at(9)];
    final snapshot = List<QuizMistakeEntry>.of(input);

    final due = SpacedRepetitionPolicy.dueEntries(input, now);
    expect(due.map((e) => e.questionId).toList(), ['p9', 'p5', 'p2', 'p1']);

    final capped = SpacedRepetitionPolicy.capDue(due, limit: 2);
    expect(capped.map((e) => e.questionId).toList(), ['p9', 'p5']);
    expect(SpacedRepetitionPolicy.capDue(due, limit: 0), isEmpty);
    expect(input, snapshot);
  });
}
