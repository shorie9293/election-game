import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/services/spaced_repetition_policy.dart';

/// 間隔反復の復習期限通知の送出計画（純粋・不変）。
///
/// 「いつ・何問・どんな文面で」通知するかを一枚に畳んだ値オブジェクト。
/// IO も現在時刻の取得も持たず、[DateTime.now] を内部で呼ばない
/// （`now` は必ず引数で注入せよ。暦が進んでも試練が赤化しないため）。
class ReviewDueNotificationPlan {
  const ReviewDueNotificationPlan({
    required this.shouldNotify,
    required this.count,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  /// 通知を送出してよいか（期限到来が1件以上あるか）。
  final bool shouldNotify;

  /// 期限到来した復習の実件数（[limit] では打ち切らない）。
  final int count;

  /// 通知の表題。
  final String title;

  /// 通知の本文。
  final String body;

  /// 送出予定時刻（ローカル暦）。
  final DateTime scheduledAt;

  /// 期限到来件数から送出計画を組み立てる。
  ///
  /// - 0 件なら送出しない（本文は空・時刻は [now] そのもの）。
  /// - 1 件以上なら「その日の hour:minute」に1日1回だけ送出する。
  ///   その時刻が既に過ぎていれば翌日の同時刻へ送る（過去時刻を予約しない）。
  /// - 本文は実件数を出す（`limit` は将来の出題上限との整合のための受け口で、
  ///   件数にも文面にも影響させない）。
  /// - 入力リストは破壊しない（読み取りのみ）。
  static ReviewDueNotificationPlan build(
    List<QuizMistakeEntry> entries, {
    required DateTime now,
    int hour = 20,
    int minute = 0,
    int limit = 10,
  }) {
    final count = SpacedRepetitionPolicy.countDue(entries, now);
    if (count == 0) {
      return ReviewDueNotificationPlan(
        shouldNotify: false,
        count: 0,
        title: '',
        body: '',
        scheduledAt: now,
      );
    }
    return ReviewDueNotificationPlan(
      shouldNotify: true,
      count: count,
      title: '📝 復習の刻',
      body: '今日の復習 $count問',
      scheduledAt: _nextSlot(now, hour: hour, minute: minute),
    );
  }

  /// 今日の hour:minute が未来ならそれ、過ぎていれば翌日の同時刻。
  ///
  /// 日付繰り上げは [Duration] ではなく暦の加算で行い、
  /// 夏時間の切り替わる地域でも「同じ壁時計の時刻」を保つ。
  static DateTime _nextSlot(
    DateTime now, {
    required int hour,
    required int minute,
  }) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  @override
  String toString() => 'ReviewDueNotificationPlan(shouldNotify: $shouldNotify, '
      'count: $count, scheduledAt: $scheduledAt)';
}
