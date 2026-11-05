import 'package:election_game/core/logging/app_logger.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/features/quiz/domain/review_due_notification_plan.dart';
import 'package:election_game/features/quiz/domain/review_due_notification_port.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';
import 'package:election_game/features/reminder/infrastructure/quiet_hours_guard_wiring.dart';
import 'package:election_game/features/reminder/infrastructure/review_due_notification_service.dart';

/// 復習期限通知のオーケストレータ。
///
/// 「復習ノートを読む → 期限到来件数を数える → 静穏時間を通す → 通知を予約する」
/// の段取りだけを担う。判定そのものは純粋層（[ReviewDueNotificationPlan]）に
/// 置き、ここでは IO の順序と失敗の握り方だけを決める。
///
/// 呼び出しは投げっぱなし（`unawaited`）を前提とするため、
/// **例外は決して外へ出さない**。通知が出ないことで学習が止まっては本末転倒なり。
class ReviewDueNotifier {
  ReviewDueNotifier({
    QuizMistakeRepository? repository,
    ReviewDueNotificationPort? port,
    QuietHoursGuard? guard,
    DateTime Function()? now,
    this.hour = 20,
    this.minute = 0,
  })  : _repository =
            repository ?? const SharedPreferencesQuizMistakeRepository(),
        _port = port ?? ReviewDueNotificationService(),
        _guard = guard,
        _now = now ?? DateTime.now;

  final QuizMistakeRepository _repository;
  final ReviewDueNotificationPort _port;

  /// 静穏時間ガード。null なら初回に [QuietHoursGuardWiring.create] で遅延生成する
  /// （Hive 初期化前に生成しても安全なのは、生成自体がリポジトリ参照だけだから）。
  QuietHoursGuard? _guard;

  /// 現在時刻の供給元（試練では固定時計を注入する）。
  final DateTime Function() _now;

  /// 通知を置く時刻（時）。
  final int hour;

  /// 通知を置く時刻（分）。
  final int minute;

  /// 再入防止。実行中に呼ばれたら何もせず false を返す。
  bool _running = false;

  /// 直近に予約した内容の指紋（同日の重複予約を防ぐ）。
  String? _lastSignature;

  /// 期限到来件数を数え直し、通知の予約／取消を反映する。
  ///
  /// 予約内容（時刻＋本文）が前回と同一なら再予約しない（冪等）。
  /// 成功時のみ true。
  Future<bool> refresh() async {
    if (_running) return false;
    _running = true;
    try {
      final entries = await _repository.load();
      final plan = ReviewDueNotificationPlan.build(
        entries,
        now: _now(),
        hour: hour,
        minute: minute,
      );

      if (!plan.shouldNotify) {
        // 期限到来が無い日は通知を残さない（前日の予約を持ち越さない）。
        _lastSignature = null;
        await _port.cancelReviewDue();
        return true;
      }

      final guard = _guard ??= QuietHoursGuardWiring.create();
      final adjusted = await guard.adjust(plan.scheduledAt);
      if (adjusted == null) {
        // 静穏時間 policy が skip：この日は送出しない。
        _lastSignature = null;
        await _port.cancelReviewDue();
        return true;
      }

      final signature = '${adjusted.toIso8601String()}|${plan.body}';
      if (signature == _lastSignature) {
        // 同一内容で既に予約済み。上書き予約しない（冪等）。
        return true;
      }

      await _port.scheduleReviewDue(
        scheduledAt: adjusted,
        title: plan.title,
        body: plan.body,
      );
      _lastSignature = signature;
      return true;
    } catch (e) {
      appLog.warn('[ReviewDueNotifier] 復習期限通知の更新失敗', e);
      return false;
    } finally {
      _running = false;
    }
  }
}
