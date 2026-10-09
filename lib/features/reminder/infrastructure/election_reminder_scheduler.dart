import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:election_game/features/reminder/infrastructure/election_notification_service.dart';

/// 通知スケジューラの抽象。画面はこの抽象にのみ依存する（テストでフェイク注入可）。
abstract class ElectionReminderScheduler {
  Future<void> apply(ElectionReminderSettings s);
  Future<void> cancel();
  Future<void> sendTestNotification();
}

/// [ElectionNotificationService] へ処理を委譲する薄い実装。
class ElectionNotificationScheduler implements ElectionReminderScheduler {
  ElectionNotificationScheduler({ElectionNotificationService? service})
      : _service = service ?? ElectionNotificationService();

  final ElectionNotificationService _service;

  @override
  Future<void> apply(ElectionReminderSettings s) async {
    if (!s.enabled) {
      await cancel();
      return;
    }
    await _service.scheduleReminder(
      hour: s.hour,
      minute: s.minute,
      weekdays: s.weekdays,
    );
  }

  @override
  Future<void> cancel() => _service.cancelReminder();

  @override
  Future<void> sendTestNotification() => _service.sendTestNotification();
}
