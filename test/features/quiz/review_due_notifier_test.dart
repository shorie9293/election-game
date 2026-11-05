import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/features/quiz/application/review_due_notifier.dart';
import 'package:election_game/features/quiz/domain/review_due_notification_port.dart';
import 'package:election_game/features/reminder/domain/quiet_hours.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';

/// 送出を記録するだけのフェイク（プラットフォームチャネルを持たない）。
class _RecordingPort implements ReviewDueNotificationPort {
  final List<({DateTime scheduledAt, String title, String body})> scheduled =
      <({DateTime scheduledAt, String title, String body})>[];
  int cancelCount = 0;

  @override
  Future<void> scheduleReviewDue({
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    scheduled.add((scheduledAt: scheduledAt, title: title, body: body));
  }

  @override
  Future<void> cancelReviewDue() async {
    cancelCount++;
  }
}

/// 読み込みで必ず失敗するリポジトリ（IO 破損の再現）。
class _ThrowingRepository implements QuizMistakeRepository {
  @override
  Future<List<QuizMistakeEntry>> load() async => throw StateError('復習ノートが読めない');

  @override
  Future<void> save(List<QuizMistakeEntry> entries) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  // 日付は必ずローカル暦で書く（UTC を混ぜると TZ 依存で赤化するため）。
  final now = DateTime(2026, 11, 5, 21, 0);
  final longAgo = now.subtract(const Duration(days: 60));

  QuizMistakeEntry entry({
    String questionId = 'q1',
    DateTime? dueAt,
    DateTime? masteredAt,
    DateTime? lastWrongAt,
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
      reviewIntervalDays: 1,
    );
  }

  /// 静穏時間なし（常にそのまま通す）ガード。
  QuietHoursGuard passThroughGuard() =>
      FixedQuietHoursGuard(QuietHoursSettings());

  ReviewDueNotifier notifier({
    required InMemoryQuizMistakeRepository repository,
    required ReviewDueNotificationPort port,
    QuietHoursGuard? guard,
  }) {
    return ReviewDueNotifier(
      repository: repository,
      port: port,
      guard: guard ?? passThroughGuard(),
      now: () => now,
    );
  }

  group('ReviewDueNotifier.refresh', () {
    test('期限到来0件なら予約せず取り消す', () async {
      final repository = InMemoryQuizMistakeRepository();
      final port = _RecordingPort();

      final result =
          await notifier(repository: repository, port: port).refresh();

      expect(result, isTrue);
      expect(port.scheduled, isEmpty);
      expect(port.cancelCount, 1);
    });

    test('期限到来ありなら1件だけ予約し、時刻と本文は計画と一致する', () async {
      final repository = InMemoryQuizMistakeRepository([
        entry(dueAt: DateTime(2026, 11, 5, 9, 0)),
        entry(questionId: 'q2', dueAt: DateTime(2026, 11, 5, 10, 0)),
      ]);
      final port = _RecordingPort();

      final result =
          await notifier(repository: repository, port: port).refresh();

      expect(result, isTrue);
      expect(port.scheduled, hasLength(1));
      final sent = port.scheduled.single;
      // 既定 hour=20:00 は now(21:00) より過去なので翌日同時刻。
      expect(sent.scheduledAt, DateTime(2026, 11, 6, 20, 0));
      expect(sent.title, '📝 復習の刻');
      expect(sent.body, '今日の復習 2問');
      expect(port.cancelCount, 0);
    });

    test('静穏時間が skip（adjust が null）なら予約せず取り消す', () async {
      final repository = InMemoryQuizMistakeRepository([
        entry(dueAt: DateTime(2026, 11, 5, 9, 0)),
      ]);
      final port = _RecordingPort();
      final guard = FixedQuietHoursGuard(
        QuietHoursSettings(
          enabled: true,
          startHour: 22,
          startMinute: 0,
          endHour: 7,
          endMinute: 0,
          policy: QuietHoursPolicy.skip,
        ),
      );

      final result = await ReviewDueNotifier(
        repository: repository,
        port: port,
        guard: guard,
        now: () => now,
        hour: 22,
      ).refresh();

      expect(result, isTrue);
      expect(port.scheduled, isEmpty);
      expect(port.cancelCount, 1);
    });

    test('静穏時間が defer なら繰り延べ時刻で予約する', () async {
      final repository = InMemoryQuizMistakeRepository([
        entry(dueAt: DateTime(2026, 11, 5, 9, 0)),
      ]);
      final port = _RecordingPort();
      final guard = FixedQuietHoursGuard(
        QuietHoursSettings(
          enabled: true,
          startHour: 22,
          startMinute: 0,
          endHour: 7,
          endMinute: 0,
          policy: QuietHoursPolicy.defer,
        ),
      );

      final result = await ReviewDueNotifier(
        repository: repository,
        port: port,
        guard: guard,
        now: () => now,
        hour: 22,
      ).refresh();

      expect(result, isTrue);
      expect(port.scheduled, hasLength(1));
      // 22:00 は静穏時間内なので翌朝 07:00 へ繰り延べられる。
      expect(port.scheduled.single.scheduledAt, DateTime(2026, 11, 6, 7, 0));
    });

    test('repository.load が失敗しても例外を外へ出さず false', () async {
      final port = _RecordingPort();

      final result = await ReviewDueNotifier(
        repository: _ThrowingRepository(),
        port: port,
        guard: passThroughGuard(),
        now: () => now,
      ).refresh();

      expect(result, isFalse);
      expect(port.scheduled, isEmpty);
      expect(port.cancelCount, 0);
    });

    test('同一状態で2回 refresh しても予約は1回（冪等）', () async {
      final repository = InMemoryQuizMistakeRepository([
        entry(dueAt: DateTime(2026, 11, 5, 9, 0)),
      ]);
      final port = _RecordingPort();
      final subject = notifier(repository: repository, port: port);

      expect(await subject.refresh(), isTrue);
      expect(await subject.refresh(), isTrue);

      expect(port.scheduled, hasLength(1));
    });

    test('件数が増えれば同じ日でも本文を更新して予約し直す', () async {
      final repository = InMemoryQuizMistakeRepository([
        entry(dueAt: DateTime(2026, 11, 5, 9, 0)),
      ]);
      final port = _RecordingPort();
      final subject = notifier(repository: repository, port: port);

      await subject.refresh();
      await repository.save([
        entry(questionId: 'q1', dueAt: DateTime(2026, 11, 5, 9, 0)),
        entry(questionId: 'q2', dueAt: DateTime(2026, 11, 5, 10, 0)),
      ]);
      await subject.refresh();

      expect(port.scheduled, hasLength(2));
      expect(port.scheduled.last.body, '今日の復習 2問');
    });
  });
}
