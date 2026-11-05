import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:election_game/core/logging/app_logger.dart';
import 'package:election_game/features/quiz/domain/review_due_notification_port.dart';
import 'package:election_game/features/reminder/domain/notification_route_resolver.dart';

/// 復習期限通知の本番実装（ローカル通知ラッパー）。
///
/// 通知IDは固定の [notificationId]（= 950）。常に同じIDへ上書き予約するため、
/// 端末に残る復習通知は常に1件だけになる（1日1通知の不変条件）。
/// タップ時は payload の route `mistakes` で誤答復習ノートへ遷移する。
///
/// プラットフォームチャネル呼出は全て try/catch で包み、
/// 失敗しても例外を投げない（MissingPluginException 対策）。
class ReviewDueNotificationService implements ReviewDueNotificationPort {
  ReviewDueNotificationService();

  /// 復習期限通知の固定ID（リマインダー 300 番台・テスト 899 と衝突させない）。
  static const int notificationId = 950;

  /// 既存リマインダーと同一の通知チャネルを使う（新規チャネルは作らない）。
  static const String channelId = 'election_reminder';
  static const String channelName = '選挙の刻';
  static const String channelDescription = '選挙リマインダーの通知';

  /// タップ先は誤答復習ノート。
  static final String _payload =
      NotificationRouteResolver.buildPayload(NotificationRoutes.mistakes);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// timezone 初期化＋プラグイン初期化＋チャネル作成を1度だけ行う。
  ///
  /// 成功したときのみ true。失敗は握って false を返す（通知は諦めて学習を妨げない）。
  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: darwin);
      await _plugin.initialize(settings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
      _initialized = true;
      return true;
    } catch (e) {
      appLog.warn('[ReviewDueNotificationService] initialize 失敗', e);
      return false;
    }
  }

  /// 復習期限通知を固定IDへ単発予約する（繰り返し指定はしない）。
  @override
  Future<void> scheduleReviewDue({
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    try {
      if (!await _ensureInitialized()) return;
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: _payload,
      );
    } catch (e) {
      // 予約失敗で学習の流れを止めない。
      appLog.warn('[ReviewDueNotificationService] scheduleReviewDue 失敗', e);
    }
  }

  /// 予約済みの復習期限通知を取り消す。
  @override
  Future<void> cancelReviewDue() async {
    try {
      await _plugin.cancel(notificationId);
    } catch (e) {
      appLog.warn('[ReviewDueNotificationService] cancelReviewDue 失敗', e);
    }
  }
}
