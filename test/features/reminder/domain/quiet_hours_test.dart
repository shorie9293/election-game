import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/reminder/domain/quiet_hours.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_delivery.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';

/// 固定時刻（十分過去・TZ=UTC 前提）。2021-03-01 は月曜。
final DateTime _mondayNoon = DateTime.utc(2021, 3, 1, 12, 0);

void main() {
  group('QuietHoursPolicy', () {
    test('storageKey は往復し、未知・null は defer へ落ちる', () {
      expect(QuietHoursPolicy.fromStorageKey('defer'), QuietHoursPolicy.defer);
      expect(QuietHoursPolicy.fromStorageKey('skip'), QuietHoursPolicy.skip);
      expect(QuietHoursPolicy.fromStorageKey('bogus'), QuietHoursPolicy.defer);
      expect(QuietHoursPolicy.fromStorageKey(null), QuietHoursPolicy.defer);
      expect(QuietHoursPolicy.skip.label, '通知しない');
      expect(QuietHoursPolicy.defer.storageKey, 'defer');
    });
  });

  group('QuietHoursSettings 範囲検証', () {
    test('時・分の範囲外は ArgumentError（非const本体で投げる）', () {
      expect(() => QuietHoursSettings(startHour: -1), throwsArgumentError);
      expect(() => QuietHoursSettings(startHour: 24), throwsArgumentError);
      expect(() => QuietHoursSettings(startMinute: -1), throwsArgumentError);
      expect(() => QuietHoursSettings(startMinute: 60), throwsArgumentError);
      expect(() => QuietHoursSettings(endHour: 24), throwsArgumentError);
      expect(() => QuietHoursSettings(endMinute: 60), throwsArgumentError);
    });

    test('copyWith でも範囲検証が効く', () {
      final s = QuietHoursSettings.defaults();
      expect(() => s.copyWith(endHour: 25), throwsArgumentError);
      expect(() => s.copyWith(startMinute: 99), throwsArgumentError);
    });

    test('既定値は 無効・22:00〜07:00・defer', () {
      final s = QuietHoursSettings.defaults();
      expect(s.enabled, isFalse);
      expect(s.startMinutes, 22 * 60);
      expect(s.endMinutes, 7 * 60);
      expect(s.policy, QuietHoursPolicy.defer);
      expect(s.isOvernight, isTrue);
      expect(s.isInactiveRange, isFalse);
    });

    test('startMinutes/endMinutes/label が時分から導出される', () {
      final s = QuietHoursSettings(startHour: 21, startMinute: 30, endHour: 6, endMinute: 45);
      expect(s.startMinutes, 1290);
      expect(s.endMinutes, 405);
      expect(s.startLabel, '21:30');
      expect(s.endLabel, '06:45');
      expect(s.label, '21:30〜06:45');
    });

    test('copyWith は指定項目のみ差し替える', () {
      final base = QuietHoursSettings.defaults();
      final next = base.copyWith(enabled: true, policy: QuietHoursPolicy.skip);
      expect(next.enabled, isTrue);
      expect(next.policy, QuietHoursPolicy.skip);
      expect(next.startHour, base.startHour);
      expect(next.endMinute, base.endMinute);
      expect(next.startMinutes, base.startMinutes);
    });

    test('値等価・hashCode 一致（別インスタンスでも等しい）', () {
      final a = QuietHoursSettings(enabled: true, startHour: 23, policy: QuietHoursPolicy.skip);
      final b = QuietHoursSettings(enabled: true, startHour: 23, policy: QuietHoursPolicy.skip);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == b.copyWith(startHour: 22), isFalse);
    });

    test('toJson/fromJson は往復する（skip も保持）', () {
      final s = QuietHoursSettings(
        enabled: true,
        startHour: 1,
        startMinute: 5,
        endHour: 4,
        endMinute: 55,
        policy: QuietHoursPolicy.skip,
      );
      final restored = QuietHoursSettings.fromJson(s.toJson());
      expect(restored, equals(s));
      expect(restored.policy, QuietHoursPolicy.skip);
    });

    test('fromJson の破損・型不正・範囲外・未知policyは既定値へ落ちる', () {
      final defaults = QuietHoursSettings.defaults();
      expect(QuietHoursSettings.fromJson(const {}), equals(defaults));
      expect(
        QuietHoursSettings.fromJson(const {'enabled': 'yes'}),
        equals(defaults),
      );
      expect(
        QuietHoursSettings.fromJson(const {
          'enabled': true,
          'startHour': 22,
          'startMinute': 0,
          'endHour': 7,
          'endMinute': 0,
          'policy': 'unknown',
        }),
        equals(defaults),
      );
      expect(
        QuietHoursSettings.fromJson(const {
          'enabled': true,
          'startHour': 99,
          'startMinute': 0,
          'endHour': 7,
          'endMinute': 0,
          'policy': 'defer',
        }),
        equals(defaults),
      );
    });
  });

  group('QuietHoursService.isWithinQuietHours', () {
    test('日跨ぎ区間 [22:00, 07:00) の内外（境界含む）', () {
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 23, 30), 1320, 420), isTrue);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 22, 0), 1320, 420), isTrue);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 2, 6, 59), 1320, 420), isTrue);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 2, 7, 0), 1320, 420), isFalse);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 21, 59), 1320, 420), isFalse);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 12, 0), 1320, 420), isFalse);
    });

    test('通常区間 [09:00, 12:00) の内外（境界含む）', () {
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 9, 0), 540, 720), isTrue);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 11, 59), 540, 720), isTrue);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 12, 0), 540, 720), isFalse);
      expect(QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 8, 59), 540, 720), isFalse);
    });

    test('start == end は常に抑止なし（false）', () {
      for (var h = 0; h < 24; h++) {
        expect(
          QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, h, 30), 600, 600),
          isFalse,
          reason: '開始==終了で抑止されてはならない',
        );
      }
    });

    test('比較は分単位（秒は無視する）', () {
      expect(
        QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 7, 0, 59), 1320, 420),
        isFalse,
      );
      expect(
        QuietHoursService.isWithinQuietHours(DateTime.utc(2021, 3, 1, 21, 59, 59), 1320, 420),
        isFalse,
      );
    });
  });

  group('QuietHoursService.deferUntil', () {
    test('日跨ぎ区間の深夜は同日の終了時刻へ繰り延べる', () {
      final deferred =
          QuietHoursService.deferUntil(DateTime(2021, 3, 1, 2, 0), 1320, 420);
      expect(deferred, DateTime(2021, 3, 1, 7, 0));
    });

    test('日跨ぎ区間の開始直後は翌日の終了時刻へ繰り延べる', () {
      final deferred = QuietHoursService.deferUntil(DateTime.utc(2021, 3, 1, 23, 30), 1320, 420);
      expect(deferred, DateTime(2021, 3, 2, 7, 0));
    });

    test('静穏時間外なら now をそのまま返す', () {
      final now = DateTime.utc(2021, 3, 1, 12, 0);
      expect(QuietHoursService.deferUntil(now, 1320, 420), now);
      expect(QuietHoursService.deferUntil(now, 600, 600), now);
    });
  });

  group('QuietHoursService.resolveDelivery', () {
    test('無効なら予定時刻のまま', () {
      final scheduled = DateTime.utc(2021, 3, 1, 23, 30);
      expect(
        QuietHoursService.resolveDelivery(QuietHoursSettings(), scheduled),
        scheduled,
      );
    });

    test('静穏時間外なら予定時刻のまま', () {
      final scheduled = DateTime.utc(2021, 3, 1, 20, 0);
      expect(
        QuietHoursService.resolveDelivery(
          QuietHoursSettings(enabled: true),
          scheduled,
        ),
        scheduled,
      );
    });

    test('defer は翌朝へ繰り延べる', () {
      expect(
        QuietHoursService.resolveDelivery(
          QuietHoursSettings(enabled: true),
          DateTime.utc(2021, 3, 1, 23, 30),
        ),
        DateTime(2021, 3, 2, 7, 0),
      );
    });

    test('skip は null（送出しない）', () {
      expect(
        QuietHoursService.resolveDelivery(
          QuietHoursSettings(enabled: true, policy: QuietHoursPolicy.skip),
          DateTime.utc(2021, 3, 1, 23, 30),
        ),
        isNull,
      );
    });

    test('start == end なら有効でも抑止しない', () {
      final scheduled = DateTime.utc(2021, 3, 1, 10, 0);
      expect(
        QuietHoursService.resolveDelivery(
          QuietHoursSettings(
            enabled: true,
            startHour: 10,
            endHour: 10,
            policy: QuietHoursPolicy.skip,
          ),
          scheduled,
        ),
        scheduled,
      );
    });
  });

  group('QuietHoursService.formatMinutes', () {
    test('ゼロ埋め HH:mm（範囲外は1日で丸める）', () {
      expect(QuietHoursService.formatMinutes(0), '00:00');
      expect(QuietHoursService.formatMinutes(90), '01:30');
      expect(QuietHoursService.formatMinutes(1320), '22:00');
      expect(QuietHoursService.formatMinutes(1439), '23:59');
      expect(QuietHoursService.formatMinutes(1440), '00:00');
      expect(QuietHoursService.formatMinutes(-60), '23:00');
    });
  });

  group('QuietHoursDeliveryPlanner', () {
    test('静穏時間外なら曜日・時刻は不変', () {
      final slots = QuietHoursDeliveryPlanner.plan(
        now: _mondayNoon,
        hour: 20,
        minute: 0,
        weekdays: const [1, 3],
        settings: QuietHoursSettings(enabled: true),
      );
      expect(slots, [
        const QuietHoursDeliverySlot(weekday: 1, hour: 20, minute: 0, deferred: false),
        const QuietHoursDeliverySlot(weekday: 3, hour: 20, minute: 0, deferred: false),
      ]);
    });

    test('defer は日跨ぎで翌曜日・終了時刻へ移る', () {
      final slots = QuietHoursDeliveryPlanner.plan(
        now: _mondayNoon,
        hour: 23,
        minute: 0,
        weekdays: const [1],
        settings: QuietHoursSettings(enabled: true),
      );
      expect(slots, hasLength(1));
      expect(slots.single.weekday, 2, reason: '月23:00 は火07:00 へ繰り延べ');
      expect(slots.single.hour, 7);
      expect(slots.single.minute, 0);
      expect(slots.single.deferred, isTrue);
    });

    test('skip は計画から消える（送出しない）', () {
      final slots = QuietHoursDeliveryPlanner.plan(
        now: _mondayNoon,
        hour: 23,
        minute: 0,
        weekdays: const [1, 2],
        settings: QuietHoursSettings(enabled: true, policy: QuietHoursPolicy.skip),
      );
      expect(slots, isEmpty);
    });

    test('無効なら深夜でも元の曜日・時刻のまま', () {
      final slots = QuietHoursDeliveryPlanner.plan(
        now: _mondayNoon,
        hour: 23,
        minute: 0,
        weekdays: const [1],
        settings: QuietHoursSettings(),
      );
      expect(slots.single.weekday, 1);
      expect(slots.single.hour, 23);
      expect(slots.single.deferred, isFalse);
    });

    test('nextOccurrenceOfWeekday は now より後の同曜日を返す', () {
      final next = QuietHoursDeliveryPlanner.nextOccurrenceOfWeekday(_mondayNoon, 1, 9, 30);
      expect(next, DateTime(2021, 3, 8, 9, 30), reason: '当日9:30は過去なので翌週');
      final sameDay = QuietHoursDeliveryPlanner.nextOccurrenceOfWeekday(_mondayNoon, 2, 9, 30);
      expect(sameDay, DateTime(2021, 3, 2, 9, 30));
    });

    test('範囲外の曜日は ArgumentError', () {
      expect(
        () => QuietHoursDeliveryPlanner.plan(
          now: _mondayNoon,
          hour: 20,
          minute: 0,
          weekdays: const [0],
          settings: QuietHoursSettings(),
        ),
        throwsArgumentError,
      );
    });

    test('同じ送出曜日に集約された場合は1件へ畳む', () {
      // 日跨ぎ defer で 月23:00→火07:00 と 日23:00→月07:00 は衝突しないが、
      // 開始=終了=23:00 の「抑止なし」では元の曜日のまま重複しないことを確認する。
      final slots = QuietHoursDeliveryPlanner.plan(
        now: _mondayNoon,
        hour: 23,
        minute: 0,
        weekdays: const [1, 1, 2],
        settings: QuietHoursSettings(),
      );
      expect(slots.map((s) => s.weekday), [1, 2]);
    });
  });
}
