import 'package:election_game/features/reminder/domain/election_reminder_schedule_service.dart';
import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = const ElectionReminderScheduleService();

  ElectionReminderSettings settings({
    bool enabled = true,
    int hour = 20,
    int minute = 0,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) {
    return ElectionReminderSettings(
      enabled: enabled,
      hour: hour,
      minute: minute,
      weekdays: weekdays,
    );
  }

  group('nextOccurrence', () {
    test('無効なら null', () {
      final s = settings(enabled: false);
      expect(service.nextOccurrence(s, DateTime(2026, 1, 5, 9, 0)), isNull);
    });

    test('平日なしなら null', () {
      final s = settings(weekdays: []);
      expect(service.nextOccurrence(s, DateTime(2026, 1, 5, 9, 0)), isNull);
    });

    test('今日の時刻が未到来なら今日', () {
      // 2026-01-05 は月曜日
      final s = settings(hour: 20);
      expect(
        service.nextOccurrence(s, DateTime(2026, 1, 5, 9, 0)),
        DateTime(2026, 1, 5, 20, 0),
      );
    });

    test('今日の時刻が到来済みなら次の対象曜日', () {
      final s = settings(hour: 8, weekdays: const [1]); // 月曜のみ
      // 月曜 9:00 → 翌週月曜
      expect(
        service.nextOccurrence(s, DateTime(2026, 1, 5, 9, 0)),
        DateTime(2026, 1, 12, 8, 0),
      );
    });

    test('対象曜日でない今日は飛ばす', () {
      final s = settings(weekdays: const [3]); // 水曜のみ
      // 月曜 9:00 → 水曜 20:00
      expect(
        service.nextOccurrence(s, DateTime(2026, 1, 5, 9, 0)),
        DateTime(2026, 1, 7, 20, 0),
      );
    });
  });

  group('occursOn / isReminderDue', () {
    test('occursOn は対象曜日判定', () {
      final s = settings(weekdays: const [1]);
      expect(service.occursOn(s, DateTime(2026, 1, 5)), isTrue); // 月
      expect(service.occursOn(s, DateTime(2026, 1, 6)), isFalse); // 火
    });

    test('isReminderDue は時刻到来後 true', () {
      final s = settings(hour: 9);
      expect(service.isReminderDue(s, DateTime(2026, 1, 5, 9, 0)), isTrue);
      expect(service.isReminderDue(s, DateTime(2026, 1, 5, 9, 1)), isTrue);
      expect(service.isReminderDue(s, DateTime(2026, 1, 5, 8, 59)), isFalse);
    });

    test('isReminderDue は無効なら false', () {
      expect(
        service.isReminderDue(settings(enabled: false), DateTime(2026, 1, 5, 9)),
        isFalse,
      );
    });
  });

  group('shouldNotify', () {
    test('到来しており本日未実施なら true', () {
      final s = settings(hour: 9);
      expect(
        service.shouldNotify(
          settings: s,
          now: DateTime(2026, 1, 5, 10, 0),
        ),
        isTrue,
      );
    });

    test('本日実施済み（lastPlayedAt が本日）なら false', () {
      final s = settings(hour: 9);
      expect(
        service.shouldNotify(
          settings: s,
          now: DateTime(2026, 1, 5, 10, 0),
          lastPlayedAt: DateTime(2026, 1, 5, 9, 5),
        ),
        isFalse,
      );
    });

    test('lastPlayedAt が昨日なら true', () {
      final s = settings(hour: 9);
      expect(
        service.shouldNotify(
          settings: s,
          now: DateTime(2026, 1, 5, 10, 0),
          lastPlayedAt: DateTime(2026, 1, 4, 18, 0),
        ),
        isTrue,
      );
    });
  });

  group('isSameDay', () {
    test('同一日判定', () {
      expect(
        service.isSameDay(DateTime(2026, 1, 5, 8), DateTime(2026, 1, 5, 23)),
        isTrue,
      );
      expect(
        service.isSameDay(DateTime(2026, 1, 5), DateTime(2026, 1, 6)),
        isFalse,
      );
    });
  });

  group('weekdayLabel', () {
    test('空は なし', () {
      expect(service.weekdayLabel(const []), 'なし');
    });

    test('7件は 毎日', () {
      expect(service.weekdayLabel(const [1, 2, 3, 4, 5, 6, 7]), '毎日');
    });

    test('平日', () {
      expect(service.weekdayLabel(const [1, 2, 3, 4, 5]), '平日');
    });

    test('土日', () {
      expect(service.weekdayLabel(const [6, 7]), '土日');
    });

    test('個別表示はソートして・接続', () {
      expect(service.weekdayLabel(const [5, 1, 3]), '月・水・金');
    });
  });

  group('timeLabel', () {
    test('ゼロ埋め HH:mm', () {
      expect(service.timeLabel(9, 5), '09:05');
      expect(service.timeLabel(20, 0), '20:00');
    });
  });

  group('upcomingOccurrences', () {
    test('count 件を昇順で返す', () {
      final s = settings(weekdays: const [1]); // 月曜 20:00
      final result = service.upcomingOccurrences(
        s,
        DateTime(2026, 1, 5, 9, 0),
        3,
      );
      expect(result, [
        DateTime(2026, 1, 5, 20, 0),
        DateTime(2026, 1, 12, 20, 0),
        DateTime(2026, 1, 19, 20, 0),
      ]);
    });

    test('count < 1 は ArgumentError', () {
      expect(
        () => service.upcomingOccurrences(
          settings(),
          DateTime(2026, 1, 5, 9, 0),
          0,
        ),
        throwsArgumentError,
      );
    });
  });
}
