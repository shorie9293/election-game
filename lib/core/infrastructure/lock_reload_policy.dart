/// 復帰時再施錠の判定を担う純粋ロジック（時刻は引数注入・TZ非依存）。
class LockReloadPolicy {
  /// 設定画面で選べる猶予（秒）。先頭が既定（即時）。
  static const List<int> graceOptionsSeconds = [0, 30, 60, 300];

  /// 猶予秒数の表示ラベル。
  static String graceLabel(int seconds) {
    switch (seconds) {
      case 0:
        return '即時';
      case 30:
        return '30秒';
      case 60:
        return '1分';
      case 300:
        return '5分';
      default:
        return '$seconds秒';
    }
  }

  /// バックグラウンド復帰時に再施錠すべきか。
  ///
  /// - 背景化時刻が無い（記録漏れ）→ true
  /// - 猶予が 0 以下 → true
  /// - 時計巻き戻し（now が背景化より前）→ true
  /// - now が背景化 + 猶予より前 → false（猶予内）
  /// - それ以外 → true
  static bool shouldRelock(
    DateTime? backgroundedAt,
    DateTime now,
    Duration grace,
  ) {
    if (backgroundedAt == null) return true;
    if (grace <= Duration.zero) return true;
    if (now.isBefore(backgroundedAt)) return true;
    final elapsed = now.difference(backgroundedAt);
    if (elapsed < grace) return false;
    return true;
  }
}
