import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:election_game/features/reminder/domain/notification_route_resolver.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_delivery.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';

/// 通知送出の抽象（スケジューラはこの抽象にのみ依存する）。
///
/// プラットフォームチャネルを持たないフェイクを注入できるため、
/// 静穏時間ガードが送出時刻決定に効いているかを試練で観測できる。
abstract class ElectionReminderNotificationPort {
  /// 曜日ごとの繰り返し通知を登録する。
  ///
  /// [now] は必ず呼び出し側から注入する（内部で [DateTime.now] を読まない）。
  /// [guard] を通した結果、送出しない曜日はキャンセルされ、
  /// 繰り延べられた曜日・時刻で再登録される。
  Future<void> scheduleReminder({
    required DateTime now,
    required int hour,
    required int minute,
    required List<int> weekdays,
    QuietHoursGuard? guard,
  });

  /// 選挙リマインダー（全曜日分）をキャンセルする。
  Future<void> cancelReminder();

  /// テスト通知を即座に送信する。
  Future<void> sendTestNotification();
}

/// 選挙リマインダー用のローカル通知ラッパー。
///
/// プラットフォームチャネル呼出は全て try/catch で包み、
/// 失敗しても例外を投げない（MissingPluginException 対策）。
class ElectionNotificationService implements ElectionReminderNotificationPort {
  ElectionNotificationService({
    QuietHoursGuard? guard,
    void Function(ResolvedNotificationRoute route)? onRouteSelected,
  })  : _guard = guard,
        _onRouteSelected = onRouteSelected;

  static const int _reminderBaseId = 300; // 通知ID = 300 + weekday(1..7)
  static const int _testNotificationId = 899;
  static const String _channelId = 'election_reminder';

  /// 通知 payload の route として許可する集合（resolver と router で共通）。
  static const Set<String> allowedRoutes = NotificationRoutes.all;

  /// リマインダー／テスト通知のタップ先（本編＝ゲーム画面）。
  static final String _defaultPayload =
      NotificationRouteResolver.buildPayload(NotificationRoutes.game);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 静穏時間ガード。null なら [scheduleReminder] の引数に従う。
  final QuietHoursGuard? _guard;

  /// 通知タップで解決された遷移先の通知先（配線は main.dart）。
  ///
  /// setter で差し替えると保留中の route を即座に引き渡す
  /// （Navigator 準備前にタップ／起動された場合の取りこぼし防止）。
  void Function(ResolvedNotificationRoute route)? get onRouteSelected =>
      _onRouteSelected;
  set onRouteSelected(void Function(ResolvedNotificationRoute route)? handler) {
    _onRouteSelected = handler;
    _drainPendingRoute();
  }

  void Function(ResolvedNotificationRoute route)? _onRouteSelected;

  /// 未配線時に保持する保留 route。
  ResolvedNotificationRoute? _pendingRoute;

  bool _initialized = false;

  /// 保留中の遷移先を取り出す（取り出しは1度だけ）。
  ///
  /// 既に [onRouteSelected] へ引き渡し済みなら null を返す。
  ResolvedNotificationRoute? consumePendingRoute() {
    final pending = _pendingRoute;
    _pendingRoute = null;
    return pending;
  }

  /// 通知 payload を解決し、保留＋配線済みなら即時通知する。
  ///
  /// 未知・破損 payload は黙って捨てる（タップ経路を壊さない）。
  void handlePayload(String? payload) {
    final resolved = NotificationRouteResolver.resolve(
      payload,
      allowedRoutes: allowedRoutes,
    );
    if (resolved == null) return;
    _pendingRoute = resolved;
    _drainPendingRoute();
  }

  /// 保留 route を配線済みの受け手へ1度だけ引き渡す。
  void _drainPendingRoute() {
    final handler = _onRouteSelected;
    if (handler == null) return;
    final pending = _pendingRoute;
    if (pending == null) return;
    _pendingRoute = null;
    handler(pending);
  }

  /// timezone 初期化＋tz.local 補正＋プラグイン初期化＋チャンネル作成。
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();

      // 端末の実際のタイムゾーンオフセットを取得し、tz.local を補正する
      final deviceOffset = DateTime.now().timeZoneOffset;
      final tzLocalOffset = tz.TZDateTime.now(tz.local).timeZoneOffset;
      if (deviceOffset != tzLocalOffset) {
        final correctTzName = _findTimezoneByOffset(deviceOffset);
        if (correctTzName != null) {
          tz.setLocalLocation(tz.getLocation(correctTzName));
        }
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: darwin);
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            '選挙の刻',
            description: '選挙リマインダーの通知',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
      _initialized = true;

      // 通知タップでアプリが起動された場合も同じ入口（handlePayload）を通す。
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        handlePayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('[ElectionNotificationService] initialize 失敗: $e');
    }
  }

  /// プラグインからのタップ通知（フォアグラウンド／バックグラウンド）。
  void _onNotificationResponse(NotificationResponse response) {
    handlePayload(response.payload);
  }

  /// 通知権限を要求する。失敗時は false。
  Future<bool> requestPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[ElectionNotificationService] requestPermission 失敗: $e');
      return false;
    }
  }

  /// 選挙リマインダーを選択曜日それぞれにスケジュールし、
  /// 未選択曜日をキャンセルする。繰り返しは毎週同時刻。
  ///
  /// 静穏時間ガード（引数優先、無ければコンストラクタ注入）を通した
  /// 送出計画に従う。skip 相当（ガードが null を返す）の曜日は登録せず
  /// キャンセルする。defer の曜日は繰り延べ後の曜日・時刻で毎週登録する。
  @override
  Future<void> scheduleReminder({
    required DateTime now,
    required int hour,
    required int minute,
    required List<int> weekdays,
    QuietHoursGuard? guard,
  }) async {
    try {
      final scheduleMode = await _getScheduleMode();
      final effectiveGuard = guard ?? _guard;
      final slots = await QuietHoursDeliveryPlanner.planWithGuard(
        now: now,
        hour: hour,
        minute: minute,
        weekdays: weekdays,
        guard: effectiveGuard,
      );
      final byWeekday = <int, QuietHoursDeliverySlot>{
        for (final slot in slots) slot.weekday: slot,
      };
      for (var weekday = 1; weekday <= 7; weekday++) {
        final id = _reminderBaseId + weekday;
        final slot = byWeekday[weekday];
        if (slot == null) {
          // 未選択曜日、および静穏時間 skip の曜日。
          await _plugin.cancel(id);
          continue;
        }
        final scheduledDate =
            _nextInstanceOfWeekday(now, slot.weekday, slot.hour, slot.minute);
        await _plugin.zonedSchedule(
          id,
          '🗳 選挙の刻',
          '選挙区の状況を確認する刻だ。',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              '選挙の刻',
              channelDescription: '選挙リマインダーの通知',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: _defaultPayload,
        );
      }
    } catch (e) {
      debugPrint('[ElectionNotificationService] scheduleReminder 失敗: $e');
    }
  }

  /// 選挙リマインダー（全曜日分）をキャンセルする。
  @override
  Future<void> cancelReminder() async {
    try {
      for (var weekday = 1; weekday <= 7; weekday++) {
        await _plugin.cancel(_reminderBaseId + weekday);
      }
    } catch (e) {
      debugPrint('[ElectionNotificationService] cancelReminder 失敗: $e');
    }
  }

  /// テスト通知を即座に送信する。
  @override
  Future<void> sendTestNotification() async {
    try {
      await _plugin.show(
        _testNotificationId,
        '🔔 テスト通知',
        '通知機能は正常に動作しています！',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'election_test',
            'テスト通知',
            channelDescription: '通知機能のテスト用',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: _defaultPayload,
      );
    } catch (e) {
      debugPrint('[ElectionNotificationService] sendTestNotification 失敗: $e');
    }
  }

  /// 正確アラーム権限があれば exact、なければ inexact へフォールバック。
  Future<AndroidScheduleMode> _getScheduleMode() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final canExact = await androidImpl
            .canScheduleExactNotifications()
            .timeout(const Duration(seconds: 2));
        if (canExact ?? false) {
          return AndroidScheduleMode.exactAllowWhileIdle;
        }
      }
    } catch (_) {
      // 権限確認に失敗したら安全側へ
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// [now] 以降で次に来る [weekday]（1=月..7=日）の [hour]:[minute] を返す。
  tz.TZDateTime _nextInstanceOfWeekday(
    DateTime now,
    int weekday,
    int hour,
    int minute,
  ) {
    final tzNow = tz.TZDateTime.from(now, tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, tzNow.year, tzNow.month, tzNow.day, hour, minute);
    while (scheduled.weekday != weekday || !scheduled.isAfter(tzNow)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// 指定されたオフセットに一致する IANA タイムゾーンを探索する。
  String? _findTimezoneByOffset(Duration offset) {
    const preferredZones = [
      'Asia/Tokyo',
      'Asia/Seoul',
      'Asia/Shanghai',
      'Asia/Taipei',
      'Asia/Hong_Kong',
      'Asia/Singapore',
      'Asia/Kolkata',
      'Europe/London',
      'Europe/Berlin',
      'Europe/Paris',
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'Pacific/Auckland',
      'Australia/Sydney',
      'UTC',
    ];

    for (final zoneName in preferredZones) {
      try {
        final location = tz.getLocation(zoneName);
        final now = tz.TZDateTime.now(location);
        if (now.timeZoneOffset == offset) {
          return zoneName;
        }
      } catch (_) {
        // 無効なゾーン名はスキップ
      }
    }

    for (final entry in tz.timeZoneDatabase.locations.entries) {
      try {
        final now = tz.TZDateTime.now(entry.value);
        if (now.timeZoneOffset == offset) {
          return entry.key;
        }
      } catch (_) {
        // 無効なゾーンはスキップ
      }
    }

    return null;
  }
}
