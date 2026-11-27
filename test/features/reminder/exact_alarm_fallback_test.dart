import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:election_game/features/reminder/infrastructure/election_notification_service.dart';

/// プラグインのモック。USE_EXACT_ALARM 撤去後、
/// 権限照会シームが inexact へのフォールバックを実際に切り替えることを
/// 実 zonedSchedule の androidScheduleMode で観測する。
class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late List<AndroidScheduleMode> observedModes;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(tz.TZDateTime.utc(2021, 3, 1));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(DateTimeComponents.dayOfWeekAndTime);
  });

  setUp(() {
    plugin = _MockPlugin();
    observedModes = <AndroidScheduleMode>[];

    when(() => plugin.cancel(any())).thenAnswer((_) async {});

    when(
      () => plugin.zonedSchedule(
        any(),
        any(),
        any(),
        any(),
        any(),
        uiLocalNotificationDateInterpretation: any(
          named: 'uiLocalNotificationDateInterpretation',
        ),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((invocation) async {
      observedModes.add(
        invocation.namedArguments[#androidScheduleMode] as AndroidScheduleMode,
      );
    });
  });

  Future<void> scheduleWith({
    required Future<bool> Function() exactAlarmAllowed,
  }) async {
    final service = ElectionNotificationService(
      plugin: plugin,
      exactAlarmAllowed: exactAlarmAllowed,
    );
    await service.scheduleReminder(
      now: DateTime.utc(2021, 3, 1, 12, 0), // 月曜正午
      hour: 23,
      minute: 0,
      weekdays: const [1],
    );
  }

  test('シームが false を返すなら inexactAllowWhileIdle で登録する', () async {
    await scheduleWith(exactAlarmAllowed: () async => false);

    expect(observedModes, isNotEmpty, reason: 'zonedSchedule が呼ばれていない');
    expect(
      observedModes,
      everyElement(AndroidScheduleMode.inexactAllowWhileIdle),
    );
  });

  test('シームが true を返すなら exactAllowWhileIdle で登録する', () async {
    await scheduleWith(exactAlarmAllowed: () async => true);

    expect(observedModes, isNotEmpty, reason: 'zonedSchedule が呼ばれていない');
    expect(
      observedModes,
      everyElement(AndroidScheduleMode.exactAllowWhileIdle),
    );
  });

  test('シームの照会が失敗したら安全側の inexactAllowWhileIdle で登録する', () async {
    await scheduleWith(exactAlarmAllowed: () async => throw StateError('boom'));

    expect(observedModes, isNotEmpty, reason: 'zonedSchedule が呼ばれていない');
    expect(
      observedModes,
      everyElement(AndroidScheduleMode.inexactAllowWhileIdle),
    );
  });
}
