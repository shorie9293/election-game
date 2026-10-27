import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/reminder/data/quiet_hours_repository.dart';
import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:election_game/features/reminder/domain/quiet_hours.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_delivery.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';
import 'package:election_game/features/reminder/infrastructure/election_notification_service.dart';
import 'package:election_game/features/reminder/infrastructure/election_reminder_scheduler.dart';
import 'package:election_game/features/reminder/infrastructure/quiet_hours_guard_wiring.dart';

/// プラットフォームチャネルを持たない記録用ポート。
class _RecordingPort implements ElectionReminderNotificationPort {
  DateTime? lastNow;
  int? lastHour;
  int? lastMinute;
  List<int>? lastWeekdays;
  List<QuietHoursDeliverySlot> slots = const [];
  int scheduledCount = 0;
  int cancelCount = 0;
  int testNotificationCount = 0;

  @override
  Future<void> scheduleReminder({
    required DateTime now,
    required int hour,
    required int minute,
    required List<int> weekdays,
    QuietHoursGuard? guard,
  }) async {
    scheduledCount++;
    lastNow = now;
    lastHour = hour;
    lastMinute = minute;
    lastWeekdays = weekdays;
    slots = await QuietHoursDeliveryPlanner.planWithGuard(
      now: now,
      hour: hour,
      minute: minute,
      weekdays: weekdays,
      guard: guard,
    );
  }

  @override
  Future<void> cancelReminder() async {
    cancelCount++;
  }

  @override
  Future<void> sendTestNotification() async {
    testNotificationCount++;
  }
}

final DateTime _mondayNoon = DateTime.utc(2021, 3, 1, 12, 0);

ElectionReminderSettings _enabled({int hour = 23, int minute = 0}) =>
    ElectionReminderSettings(enabled: true, hour: hour, minute: minute);

void main() {
  group('スケジューラ → 通知ポートへの静穏時間の配線', () {
    tearDown(QuietHoursGuardWiring.reset);

    test('defer: 23:00 の毎日通知は翌朝 07:00 の計画になる', () async {
      final port = _RecordingPort();
      final scheduler = ElectionNotificationScheduler(
        port: port,
        guard: QuietHoursRepositoryGuard(
          InMemoryQuietHoursRepository(QuietHoursSettings(enabled: true)),
        ),
        now: () => _mondayNoon,
      );

      await scheduler.apply(_enabled());

      expect(port.scheduledCount, 1);
      expect(port.lastNow, _mondayNoon, reason: 'now は注入値であること');
      expect(port.lastHour, 23);
      expect(port.slots, hasLength(7));
      for (final slot in port.slots) {
        expect(slot.hour, 7, reason: '日跨ぎ区間の終了時刻へ繰り延べ');
        expect(slot.minute, 0);
        expect(slot.deferred, isTrue);
      }
      // 計画は送出曜日でソートされるため、月23:00 → 火07:00 の繰延で
      // 曜日の並びは [1..7] のまま（時刻だけが 07:00 へ移る）。
      expect(port.slots.map((s) => s.weekday), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('skip: 静穏時間内の通知は計画から消える（送出しない）', () async {
      final port = _RecordingPort();
      final scheduler = ElectionNotificationScheduler(
        port: port,
        guard: QuietHoursRepositoryGuard(
          InMemoryQuietHoursRepository(
            QuietHoursSettings(enabled: true, policy: QuietHoursPolicy.skip),
          ),
        ),
        now: () => _mondayNoon,
      );

      await scheduler.apply(_enabled());

      expect(port.slots, isEmpty);
    });

    test('静穏時間無効なら元の時刻のまま7曜日', () async {
      final port = _RecordingPort();
      final scheduler = ElectionNotificationScheduler(
        port: port,
        guard: QuietHoursRepositoryGuard(InMemoryQuietHoursRepository()),
        now: () => _mondayNoon,
      );

      await scheduler.apply(_enabled());

      expect(port.slots, hasLength(7));
      expect(port.slots.every((s) => s.hour == 23 && !s.deferred), isTrue);
    });

    test('通知設定OFFなら cancel のみ（scheduleReminder は呼ばない）', () async {
      final port = _RecordingPort();
      final scheduler = ElectionNotificationScheduler(
        port: port,
        now: () => _mondayNoon,
      );

      await scheduler.apply(ElectionReminderSettings());

      expect(port.cancelCount, 1);
      expect(port.scheduledCount, 0);
    });

    test('guard 未指定でも既定結線がリポジトリの設定を読む（保存が効く）',
        () async {
      final repository = InMemoryQuietHoursRepository(
        QuietHoursSettings(enabled: true, policy: QuietHoursPolicy.skip),
      );
      QuietHoursGuardWiring.repositoryFactory = () => repository;

      final port = _RecordingPort();
      final scheduler = ElectionNotificationScheduler(
        port: port,
        now: () => _mondayNoon,
      );

      await scheduler.apply(_enabled());

      expect(repository.loadCount, greaterThan(0));
      expect(port.slots, isEmpty,
          reason: '設定画面で保存した skip が本番の送出計画へ反映されること');
    });

    test('テスト通知はガードを通さず即時送出する', () async {
      final port = _RecordingPort();
      final scheduler = ElectionNotificationScheduler(
        port: port,
        guard: QuietHoursRepositoryGuard(
          InMemoryQuietHoursRepository(
            QuietHoursSettings(enabled: true, policy: QuietHoursPolicy.skip),
          ),
        ),
        now: () => _mondayNoon,
      );

      await scheduler.sendTestNotification();

      expect(port.testNotificationCount, 1);
    });
  });

  group('QuietHoursRepositoryGuard', () {
    test('静穏時間内は繰延時刻、外は素通し、skip は null', () async {
      final guard = QuietHoursRepositoryGuard(
        InMemoryQuietHoursRepository(QuietHoursSettings(enabled: true)),
      );
      expect(
        await guard.adjust(DateTime.utc(2021, 3, 1, 23, 0)),
        DateTime(2021, 3, 2, 7, 0),
      );
      final noon = DateTime.utc(2021, 3, 1, 12, 0);
      expect(await guard.adjust(noon), noon);

      final skipGuard = QuietHoursRepositoryGuard(
        InMemoryQuietHoursRepository(
          QuietHoursSettings(enabled: true, policy: QuietHoursPolicy.skip),
        ),
      );
      expect(await skipGuard.adjust(DateTime.utc(2021, 3, 1, 23, 0)), isNull);
    });
  });
}
