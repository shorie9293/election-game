import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';
import 'package:election_game/features/reminder/infrastructure/election_notification_service.dart';
import 'package:election_game/features/reminder/infrastructure/quiet_hours_guard_wiring.dart';

/// 通知スケジューラの抽象。画面はこの抽象にのみ依存する（テストでフェイク注入可）。
abstract class ElectionReminderScheduler {
  Future<void> apply(ElectionReminderSettings s);
  Future<void> cancel();
  Future<void> sendTestNotification();
}

/// 通知送出ポートへ処理を委譲する薄い実装。
///
/// 送出時刻の決定は静穏時間ガードに委ねる（defer=繰延 / skip=送出しない）。
/// [guard] 未指定なら [QuietHoursGuardWiring.create] を通るため、
/// 設定画面で保存した静穏時間設定が本番経路へ自動的に反映される。
class ElectionNotificationScheduler implements ElectionReminderScheduler {
  ElectionNotificationScheduler({
    ElectionNotificationService? service,
    ElectionReminderNotificationPort? port,
    QuietHoursGuard? guard,
    DateTime Function()? now,
  })  : _port = port ?? service ?? ElectionNotificationService(),
        _guard = guard,
        _now = now ?? DateTime.now;

  final ElectionReminderNotificationPort _port;
  final DateTime Function() _now;

  /// 明示注入されたガード。null なら初回 apply 時に既定結線から生成する。
  QuietHoursGuard? _guard;

  @override
  Future<void> apply(ElectionReminderSettings s) async {
    if (!s.enabled) {
      await cancel();
      return;
    }
    _guard ??= QuietHoursGuardWiring.create();
    await _port.scheduleReminder(
      now: _now(),
      hour: s.hour,
      minute: s.minute,
      weekdays: s.weekdays,
      guard: _guard,
    );
  }

  @override
  Future<void> cancel() => _port.cancelReminder();

  @override
  Future<void> sendTestNotification() => _port.sendTestNotification();
}
