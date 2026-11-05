/// 復習期限通知の送出先の抽象。
///
/// オーケストレータ（`ReviewDueNotifier`）はこの抽象にのみ依存せよ。
/// プラットフォームチャネルを持たないフェイクを注入できるため、
/// 「いつ・何件」送出したかを試練で観測できる。
abstract class ReviewDueNotificationPort {
  /// 復習期限通知を1件だけ予約する（同一IDへ上書き＝常に最新1件）。
  Future<void> scheduleReviewDue({
    required DateTime scheduledAt,
    required String title,
    required String body,
  });

  /// 予約済みの復習期限通知を取り消す。
  Future<void> cancelReviewDue();
}
