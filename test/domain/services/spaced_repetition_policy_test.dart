import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/services/quiz_mistake_service.dart';
import 'package:election_game/domain/services/quiz_service.dart';
import 'package:election_game/domain/services/spaced_repetition_policy.dart';

void main() {
  final now = DateTime(2026, 10, 13, 10, 0);
  const day = Duration(days: 1);
  // dueAt の不変条件（lastWrongAt 以上）を満たすための十分に古い基準日時。
  final longAgo = now.subtract(const Duration(days: 60));

  QuizMistakeEntry entry({
    String questionId = 'q1',
    QuizCategory category = QuizCategory.system,
    int correctIndex = 1,
    int wrongCount = 1,
    int? lastSelectedIndex = 0,
    DateTime? lastWrongAt,
    DateTime? masteredAt,
    DateTime? dueAt,
    int reviewIntervalDays = 0,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: category,
      correctIndex: correctIndex,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex,
      lastWrongAt: lastWrongAt ?? longAgo,
      masteredAt: masteredAt,
      dueAt: dueAt,
      reviewIntervalDays: reviewIntervalDays,
    );
  }

  test('intervals は 1,3,7,14,30 の段階を持つ', () {
    expect(SpacedRepetitionPolicy.intervals, [1, 3, 7, 14, 30]);
  });

  group('onWrong', () {
    test('期限を now + 1日・間隔を1日にリセットする', () {
      final updated = SpacedRepetitionPolicy.onWrong(
        entry(reviewIntervalDays: 14, dueAt: now.add(const Duration(days: 14))),
        now: now,
      );
      expect(updated.dueAt, now.add(day));
      expect(updated.reviewIntervalDays, 1);
    });

    test('克服済みでも間隔を1日へ戻す（masteredAt は保持）', () {
      final mastered = entry(masteredAt: now, reviewIntervalDays: 7);
      final updated = SpacedRepetitionPolicy.onWrong(mastered, now: now);
      expect(updated.reviewIntervalDays, 1);
      expect(updated.dueAt, now.add(day));
      expect(updated.masteredAt, now);
    });

    test('時計が巻き戻っても dueAt は lastWrongAt より前にならない', () {
      final base = now;
      final earlier = now.subtract(const Duration(days: 5));
      final updated = SpacedRepetitionPolicy.onWrong(
        entry(lastWrongAt: base),
        now: earlier,
      );
      expect(updated.dueAt, base.add(day));
      expect(updated.dueAt.isBefore(base), isFalse);
    });
  });

  group('onCorrect', () {
    test('間隔が 1→3→7→14→30 と伸び、30 で頭打ちになる', () {
      var current = entry();
      final seen = <int>[];
      for (var i = 0; i < 6; i++) {
        current = SpacedRepetitionPolicy.onCorrect(current, now: now);
        seen.add(current.reviewIntervalDays);
      }
      expect(seen, [1, 3, 7, 14, 30, 30]);
    });

    test('期限は now + 新しい間隔日数になる', () {
      final updated = SpacedRepetitionPolicy.onCorrect(
        entry(reviewIntervalDays: 3),
        now: now,
      );
      expect(updated.reviewIntervalDays, 7);
      expect(updated.dueAt, now.add(const Duration(days: 7)));
    });

    test('克服日時を now で記録する', () {
      final updated = SpacedRepetitionPolicy.onCorrect(entry(), now: now);
      expect(updated.masteredAt, now);
      expect(updated.isMastered, isTrue);
    });

    test('時計が巻き戻っても例外を出さず lastWrongAt でクランプする', () {
      final earlier = now.subtract(const Duration(days: 3));
      final updated = SpacedRepetitionPolicy.onCorrect(
        entry(lastWrongAt: now),
        now: earlier,
      );
      expect(updated.masteredAt, now);
      expect(updated.dueAt, now.add(day));
      expect(updated.dueAt.isBefore(now), isFalse);
    });

    test('未知の間隔（段階外）は次の段階へ丸める', () {
      final updated = SpacedRepetitionPolicy.onCorrect(
        entry(reviewIntervalDays: 5),
        now: now,
      );
      expect(updated.reviewIntervalDays, 7);
    });
  });

  group('isDue', () {
    test('期限前は false・期限ちょうどと期限後は true', () {
      final target = entry(dueAt: now.add(const Duration(hours: 1)));
      expect(SpacedRepetitionPolicy.isDue(target, now), isFalse);
      expect(
        SpacedRepetitionPolicy.isDue(target, now.add(const Duration(hours: 1))),
        isTrue,
      );
      expect(
        SpacedRepetitionPolicy.isDue(target, now.add(const Duration(days: 2))),
        isTrue,
      );
    });

    test('克服済みでも期限経過なら再確認対象（true）', () {
      final mastered = entry(
        masteredAt: now,
        dueAt: now.add(const Duration(days: 3)),
        reviewIntervalDays: 3,
      );
      expect(
        SpacedRepetitionPolicy.isDue(
            mastered, now.add(const Duration(days: 2))),
        isFalse,
      );
      expect(
        SpacedRepetitionPolicy.isDue(
            mastered, now.add(const Duration(days: 3))),
        isTrue,
      );
    });
  });

  group('dueEntries / countDue', () {
    test('期限到来分のみを dueAt 昇順 → 問題ID昇順で返す', () {
      final entries = [
        entry(questionId: 'b', dueAt: now.subtract(const Duration(days: 3))),
        entry(questionId: 'a', dueAt: now.subtract(const Duration(days: 3))),
        entry(questionId: 'c', dueAt: now.subtract(const Duration(days: 1))),
        entry(questionId: 'z', dueAt: now.add(const Duration(days: 9))),
      ];
      final due = SpacedRepetitionPolicy.dueEntries(entries, now);
      expect(due.map((e) => e.questionId).toList(), ['a', 'b', 'c']);
      expect(SpacedRepetitionPolicy.countDue(entries, now), 3);
    });

    test('入力リストは変更しない・結果は unmodifiable', () {
      final entries = [
        entry(questionId: 'b', dueAt: now.add(const Duration(days: 2))),
        entry(questionId: 'a', dueAt: now.subtract(const Duration(days: 1))),
      ];
      final due = SpacedRepetitionPolicy.dueEntries(entries, now);
      expect(entries.map((e) => e.questionId).toList(), ['b', 'a']);
      expect(() => due.add(entry(questionId: 'x')), throwsUnsupportedError);
    });

    test('期限到来が無ければ空・0件', () {
      final entries = [entry(dueAt: now.add(const Duration(days: 1)))];
      expect(SpacedRepetitionPolicy.dueEntries(entries, now), isEmpty);
      expect(SpacedRepetitionPolicy.countDue(entries, now), 0);
    });
  });

  group('capDue', () {
    List<QuizMistakeEntry> dueList(int count) => [
          for (var i = 0; i < count; i++)
            entry(
                questionId: 'q$i', dueAt: now.subtract(Duration(days: 10 - i))),
        ];

    test('limit 件に切り詰める（既定は10件）', () {
      final entries = dueList(15);
      expect(SpacedRepetitionPolicy.capDue(entries).length, 10);
      expect(SpacedRepetitionPolicy.capDue(entries, limit: 3).length, 3);
      expect(
        SpacedRepetitionPolicy.capDue(entries, limit: 3)
            .map((e) => e.questionId)
            .toList(),
        ['q0', 'q1', 'q2'],
      );
    });

    test('件数が limit 以下ならそのまま全件', () {
      expect(SpacedRepetitionPolicy.capDue(dueList(4), limit: 5).length, 4);
    });

    test('limit が 0 以下なら空', () {
      final entries = dueList(3);
      expect(SpacedRepetitionPolicy.capDue(entries, limit: 0), isEmpty);
      expect(SpacedRepetitionPolicy.capDue(entries, limit: -1), isEmpty);
    });

    test('入力リストは変更しない', () {
      final entries = dueList(5);
      final capped = SpacedRepetitionPolicy.capDue(entries, limit: 2);
      expect(entries.length, 5);
      expect(() => capped.add(entry(questionId: 'x')), throwsUnsupportedError);
    });

    test('dueEntries と組み合わせて期限の早い順に切れる', () {
      final entries = [
        entry(questionId: 'late', dueAt: now.subtract(day)),
        entry(
            questionId: 'early', dueAt: now.subtract(const Duration(days: 3))),
        entry(questionId: 'future', dueAt: now.add(day)),
      ];
      final capped = SpacedRepetitionPolicy.capDue(
        SpacedRepetitionPolicy.dueEntries(entries, now),
        limit: 1,
      );
      expect(capped.single.questionId, 'early');
    });
  });

  group('QuizMistakeService.record との統合', () {
    final questions = <QuizQuestion>[
      QuizQuestion(
        id: 'q1',
        category: QuizCategory.system,
        question: '衆議院議員の任期は？',
        choices: const ['2年', '4年', '6年'],
        correctIndex: 1,
        explanation: '衆議院議員の任期は4年です。',
      ),
    ];

    test('誤答記録で期限が翌日・間隔1日になる', () {
      final entries = QuizMistakeService.record(
        const [],
        questions,
        QuizService.grade(questions, [0]),
        now: now,
      );
      final q1 = entries.single;
      expect(q1.reviewIntervalDays, 1);
      expect(q1.dueAt, now.add(day));
      expect(SpacedRepetitionPolicy.isDue(q1, now), isFalse);
    });

    test('翌日以降の正解で間隔が次の段階へ進む', () {
      final first = QuizMistakeService.record(
        const [],
        questions,
        QuizService.grade(questions, [0]),
        now: now,
      );
      final next = now.add(day);
      final second = QuizMistakeService.record(
        first,
        questions,
        QuizService.grade(questions, [1]),
        now: next,
      );
      final q1 = second.single;
      expect(q1.isMastered, isTrue);
      expect(q1.masteredAt, next);
      expect(q1.reviewIntervalDays, 3);
      expect(q1.dueAt, next.add(const Duration(days: 3)));
    });

    test('再度誤答すると期限が翌日へ戻る', () {
      final first = QuizMistakeService.record(
        const [],
        questions,
        QuizService.grade(questions, [0]),
        now: now,
      );
      final later = now.add(const Duration(days: 5));
      final second = QuizMistakeService.record(
        first,
        questions,
        QuizService.grade(questions, [0]),
        now: later,
      );
      final q1 = second.single;
      expect(q1.reviewIntervalDays, 1);
      expect(q1.dueAt, later.add(day));
    });
  });
}
