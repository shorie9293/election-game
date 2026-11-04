import '../models/quiz_mistake_entry.dart';

/// 間隔反復（spaced repetition）の純粋ロジック。
///
/// IO を持たず、すべて static な純粋関数として提供する。
/// 時刻は必ず名前付き引数 `now` で受け取り、内部で `DateTime.now()` を
/// 呼ばない（暦が進んでも試練が赤化しないようにするため）。
/// 端末時計が巻き戻っている場合（`now` が [QuizMistakeEntry.lastWrongAt] より
/// 過去）でも、[QuizMistakeEntry] の不変条件を破らないよう基準時刻を
/// 誤答日時までクランプする。
class SpacedRepetitionPolicy {
  SpacedRepetitionPolicy._();

  /// 復習間隔の段階（日数）。0 は未設定を表し、正解で 1 段目へ進む。
  static const List<int> intervals = [1, 3, 7, 14, 30];

  /// 誤答時の更新：間隔を 1 日に戻し、期限を翌日にする。
  static QuizMistakeEntry onWrong(
    QuizMistakeEntry entry, {
    required DateTime now,
  }) {
    final base = _base(entry, now);
    return entry.copyWith(
      reviewIntervalDays: intervals.first,
      dueAt: base.add(Duration(days: intervals.first)),
    );
  }

  /// 正解時の更新：間隔を次の段階へ進め、期限をその日数後に置く。
  ///
  /// 最大段階（[intervals] の末尾）に達したら頭打ちにする。
  /// [QuizMistakeEntry.masteredAt] も同時に記録する（クランプ込み）。
  static QuizMistakeEntry onCorrect(
    QuizMistakeEntry entry, {
    required DateTime now,
  }) {
    final next = _nextInterval(entry.reviewIntervalDays);
    final base = _base(entry, now);
    return entry.copyWith(
      reviewIntervalDays: next,
      dueAt: base.add(Duration(days: next)),
      masteredAt: base,
    );
  }

  /// 復習期限が到来しているか（dueAt <= now）。
  ///
  /// 克服済みでも期限が経過すれば再確認の対象に戻る（mastered を問わず判定）。
  static bool isDue(QuizMistakeEntry entry, DateTime now) =>
      !entry.dueAt.isAfter(now);

  /// 期限到来分のみを「期限の早い順 → 問題ID昇順」で返す（入力は変更しない）。
  static List<QuizMistakeEntry> dueEntries(
    List<QuizMistakeEntry> entries,
    DateTime now,
  ) {
    final list = entries.where((e) => isDue(e, now)).toList(growable: false);
    final sorted = List<QuizMistakeEntry>.of(list);
    sorted.sort((a, b) {
      final byDue = a.dueAt.compareTo(b.dueAt);
      if (byDue != 0) return byDue;
      return a.questionId.compareTo(b.questionId);
    });
    return List<QuizMistakeEntry>.unmodifiable(sorted);
  }

  /// 期限到来件数。
  static int countDue(List<QuizMistakeEntry> entries, DateTime now) =>
      entries.where((e) => isDue(e, now)).length;

  /// 先頭 [limit] 件に切り詰める（`limit <= 0` なら空・入力は変更しない）。
  ///
  /// 並べ替えはしない。[dueEntries] の結果に適用する想定。
  static List<QuizMistakeEntry> capDue(
    List<QuizMistakeEntry> entries, {
    int limit = 10,
  }) {
    if (limit <= 0) return List<QuizMistakeEntry>.unmodifiable(const []);
    final capped = entries.take(limit).toList(growable: false);
    return List<QuizMistakeEntry>.unmodifiable(capped);
  }

  /// クランプ済みの基準時刻（`now < lastWrongAt` なら誤答日時）。
  static DateTime _base(QuizMistakeEntry entry, DateTime now) =>
      now.isBefore(entry.lastWrongAt) ? entry.lastWrongAt : now;

  /// 現在の間隔より大きい最小の段階（無ければ最大段階）。
  static int _nextInterval(int current) {
    for (final interval in intervals) {
      if (interval > current) return interval;
    }
    return intervals.last;
  }
}
