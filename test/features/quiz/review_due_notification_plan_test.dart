import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/features/quiz/domain/review_due_notification_plan.dart';

void main() {
  // 日付は必ずローカル暦で書く（UTC を混ぜると TZ 依存で赤化するため）。
  final now = DateTime(2026, 11, 5, 21, 0);
  // dueAt の不変条件（lastWrongAt 以上）を満たすための十分に古い基準日時。
  final longAgo = now.subtract(const Duration(days: 60));

  QuizMistakeEntry entry({
    String questionId = 'q1',
    DateTime? lastWrongAt,
    DateTime? masteredAt,
    DateTime? dueAt,
    int reviewIntervalDays = 1,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: QuizCategory.system,
      correctIndex: 1,
      wrongCount: 1,
      lastSelectedIndex: 0,
      lastWrongAt: lastWrongAt ?? longAgo,
      masteredAt: masteredAt,
      dueAt: dueAt,
      reviewIntervalDays: reviewIntervalDays,
    );
  }

  group('ReviewDueNotificationPlan.build', () {
    test('期限到来0件なら送出しない・本文は空・時刻は now', () {
      final plan = ReviewDueNotificationPlan.build(
        const <QuizMistakeEntry>[],
        now: now,
      );

      expect(plan.shouldNotify, isFalse);
      expect(plan.count, 0);
      expect(plan.body, '');
      expect(plan.scheduledAt, now);
    });

    test('1件なら本文は「今日の復習 1問」・表題は復習の刻', () {
      final plan = ReviewDueNotificationPlan.build(
        [entry(dueAt: DateTime(2026, 11, 5, 9, 0))],
        now: now,
      );

      expect(plan.shouldNotify, isTrue);
      expect(plan.count, 1);
      expect(plan.body, '今日の復習 1問');
      expect(plan.title, '📝 復習の刻');
    });

    test('N件なら件数がそのまま本文へ出る', () {
      final plan = ReviewDueNotificationPlan.build(
        [
          entry(questionId: 'q1', dueAt: DateTime(2026, 11, 4, 9, 0)),
          entry(questionId: 'q2', dueAt: DateTime(2026, 11, 5, 9, 0)),
          entry(questionId: 'q3', dueAt: DateTime(2026, 11, 5, 20, 0)),
        ],
        now: now,
      );

      expect(plan.count, 3);
      expect(plan.body, '今日の復習 3問');
    });

    test('通知時刻が未来なら当日のその時刻に置く', () {
      final plan = ReviewDueNotificationPlan.build(
        [entry(dueAt: DateTime(2026, 11, 5, 9, 0))],
        now: now,
        hour: 22,
        minute: 30,
      );

      expect(plan.scheduledAt, DateTime(2026, 11, 5, 22, 30));
    });

    test('通知時刻が既に過ぎていれば翌日の同時刻へ送る', () {
      final plan = ReviewDueNotificationPlan.build(
        [entry(dueAt: DateTime(2026, 11, 5, 9, 0))],
        now: now,
        hour: 20,
        minute: 0,
      );

      expect(plan.scheduledAt, DateTime(2026, 11, 6, 20, 0));
      expect(plan.scheduledAt.isAfter(now), isTrue);
    });

    test('通知時刻ちょうど（now と同時刻）は過去扱いで翌日へ送る', () {
      final plan = ReviewDueNotificationPlan.build(
        [entry(dueAt: DateTime(2026, 11, 5, 9, 0))],
        now: now,
        hour: 21,
        minute: 0,
      );

      expect(plan.scheduledAt, DateTime(2026, 11, 6, 21, 0));
    });

    test('limit を超える件数でも count は実件数（本文に limit は出さない）', () {
      final entries = [
        for (var i = 0; i < 15; i++)
          entry(questionId: 'q$i', dueAt: DateTime(2026, 11, 5, 9, 0)),
      ];

      final plan = ReviewDueNotificationPlan.build(
        entries,
        now: now,
        limit: 10,
      );

      expect(plan.count, 15);
      expect(plan.body, '今日の復習 15問');
    });

    test('入力リストを破壊しない', () {
      final entries = [
        entry(questionId: 'q1', dueAt: DateTime(2026, 11, 4, 9, 0)),
        entry(questionId: 'q2', dueAt: DateTime(2026, 11, 5, 9, 0)),
      ];
      final snapshot = List<QuizMistakeEntry>.of(entries);

      ReviewDueNotificationPlan.build(entries, now: now);

      expect(entries, snapshot);
      expect(entries.length, 2);
    });

    test('期限前（now が dueAt より前）は数えない', () {
      final plan = ReviewDueNotificationPlan.build(
        [entry(dueAt: DateTime(2026, 11, 6, 9, 0))],
        now: now,
      );

      expect(plan.shouldNotify, isFalse);
      expect(plan.count, 0);
    });

    test('期限当日（同日の朝）は到来として数える', () {
      final plan = ReviewDueNotificationPlan.build(
        [entry(dueAt: DateTime(2026, 11, 5, 0, 0))],
        now: now,
      );

      expect(plan.shouldNotify, isTrue);
      expect(plan.count, 1);
    });

    test('克服済みでも期限到来なら数える（#206 の不変条件）', () {
      final plan = ReviewDueNotificationPlan.build(
        [
          entry(
            dueAt: DateTime(2026, 11, 5, 9, 0),
            masteredAt: DateTime(2026, 11, 1, 9, 0),
          ),
        ],
        now: now,
      );

      expect(plan.shouldNotify, isTrue);
      expect(plan.count, 1);
    });

    test('期限到来と未到来が混在すれば到来分だけ数える', () {
      final plan = ReviewDueNotificationPlan.build(
        [
          entry(questionId: 'q1', dueAt: DateTime(2026, 11, 5, 9, 0)),
          entry(questionId: 'q2', dueAt: DateTime(2026, 11, 8, 9, 0)),
        ],
        now: now,
      );

      expect(plan.count, 1);
      expect(plan.body, '今日の復習 1問');
    });
  });
}
