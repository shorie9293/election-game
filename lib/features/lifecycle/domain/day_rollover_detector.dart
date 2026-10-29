/// 日付跨ぎ判定の結果。
enum DayRolloverResult {
  /// ローカル暦の同日（時刻だけが進んだ）。
  sameDay,

  /// ローカル暦の日付が進んだ（跨ぎ）。
  rolledOver,

  /// ローカル暦の日付が巻き戻った（端末時計の後退・タイムゾーン変更など）。
  clockWentBack,
}

/// 「最後に見た日」と「今」をローカル暦（年/月/日）で比較する純粋検出器。
///
/// 判定・更新の規則:
/// - 同日 → [DayRolloverResult.sameDay]、lastSeen を now へ更新
/// - 日付が進んだ → [DayRolloverResult.rolledOver]、lastSeen を now へ更新
/// - 日付が巻き戻った → [DayRolloverResult.clockWentBack]、lastSeen は据え置き
///
/// 端末時計の後退は例外にせずクランプする（アプリを落とさない）。
/// UTC を混ぜると JST の深夜帯で1日ずれるため、判定は必ずローカル暦で行う。
class DayRolloverDetector {
  DayRolloverDetector({required DateTime lastSeen}) : _lastSeen = lastSeen;

  DateTime _lastSeen;

  /// 直近で確定した「見た時刻」。
  DateTime get lastSeen => _lastSeen;

  /// [now] を突き合わせ、結果に応じて内部状態を更新する。
  DayRolloverResult check(DateTime now) {
    final lastDay = DateTime(_lastSeen.year, _lastSeen.month, _lastSeen.day);
    final today = DateTime(now.year, now.month, now.day);

    if (today == lastDay) {
      _lastSeen = now;
      return DayRolloverResult.sameDay;
    }
    if (today.isAfter(lastDay)) {
      _lastSeen = now;
      return DayRolloverResult.rolledOver;
    }
    // 巻き戻し: lastSeen は据え置く（次回の跨ぎ判定の基準を壊さない）。
    return DayRolloverResult.clockWentBack;
  }
}
