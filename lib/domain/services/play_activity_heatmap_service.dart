import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/play_activity_heatmap.dart';
import 'package:election_game/domain/services/election_archive_service.dart';

/// 選挙プレイ活動のヒートマップを構築する純粋サービス。
///
/// 副作用・I/O・現在時刻への依存は一切持たない（完全な静的メソッドのみ）。
/// now は必ず呼び出し側から渡す（サービス内で DateTime.now() を呼ばない）。
class PlayActivityHeatmapService {
  PlayActivityHeatmapService._();

  /// ローカル日付キー 'YYYY-MM-DD'（月・日はゼロ埋め2桁）。
  static String dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$m-$d';
  }

  /// 選挙リストから日付別実施回数を集計。
  ///
  /// - ElectionArchiveService.timestampFromId(e.id) が null の選挙は無視。
  /// - 復元した DateTime を toLocal() してローカル日付単位で件数を数える。
  /// - 同日複数選挙は件数加算。
  static Map<String, int> countsByDate(Iterable<Election> elections) {
    final counts = <String, int>{};
    for (final e in elections) {
      final ts = ElectionArchiveService.timestampFromId(e.id);
      if (ts == null) continue;
      final local = ts.toLocal();
      final key = dateKey(local);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  /// 活動量→濃淡レベル(0..4)。
  ///
  /// - maxCount<=0 または count<=0 は 0。
  /// - count>=maxCount は 4。
  /// - それ以外は (count * 4 / maxCount).ceil() を 1..4 にクランプ。
  static int levelOf(int count, int maxCount) {
    if (maxCount <= 0 || count <= 0) return 0;
    if (count >= maxCount) return 4;
    final level = (count * 4 / maxCount).ceil();
    if (level < 1) return 1;
    if (level > 4) return 4;
    return level;
  }

  /// ヒートマップ構築。
  ///
  /// - now の属する週を最終列とし、weeks 列（既定26）を過去へ遡る。
  /// - 各列は日曜始まりの7日（日曜..土曜）。
  /// - now より未来の日付は count 0。
  /// - now はローカル時刻として扱う（内部で正規化）。
  /// - weeks<=0 は ArgumentError を throw。
  static PlayActivityHeatmap build(
    Iterable<Election> elections, {
    required DateTime now,
    int weeks = 26,
  }) {
    if (weeks <= 0) throw ArgumentError.value(weeks, 'weeks', 'must be > 0');

    final localNow = now.toLocal();
    final nowDate = DateTime(localNow.year, localNow.month, localNow.day);
    final counts = countsByDate(elections);

    // 最終列の土曜（now を含む週の終わり）
    final daysUntilSunday = nowDate.weekday % 7; // 日曜=7→0, 月曜=1...
    final lastSunday = nowDate.subtract(Duration(days: daysUntilSunday));

    // グリッド構築（最終列 = now を含む週、日曜始まり・古い週→新しい週）
    final resultWeeks = <PlayActivityWeek>[];
    for (var w = weeks - 1; w >= 0; w--) {
      final weekStart = lastSunday.subtract(Duration(days: 7 * w));
      final days = <PlayActivityDay>[];
      for (var i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final count = date.isAfter(nowDate) ? 0 : (counts[dateKey(date)] ?? 0);
        days.add(PlayActivityDay(date: date, count: count));
      }
      resultWeeks.add(PlayActivityWeek(days: days));
    }

    // 集計は countsByDate の全データから取る（グリッド外の日も含む）。
    var totalElections = 0;
    var activeDays = 0;
    var maxCount = 0;
    String? busiestKey;
    final sortedKeys = counts.keys.toList()..sort();
    for (final key in sortedKeys) {
      final count = counts[key] ?? 0;
      if (count <= 0) continue;
      totalElections += count;
      activeDays++;
      if (count > maxCount) maxCount = count;
      // キーは 'YYYY-MM-DD' なので文字列昇順 = 日付昇順。同数なら最初を採用。
      if (busiestKey == null || count > (counts[busiestKey] ?? 0)) {
        busiestKey = key;
      }
    }

    PlayActivityDay? busiestDay;
    if (busiestKey != null) {
      final parts = busiestKey.split('-');
      busiestDay = PlayActivityDay(
        date: DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ),
        count: counts[busiestKey] ?? 0,
      );
    }

    // longestStreak: ソート済みキー上の暦連日最長
    var longestStreak = 0;
    var runningStreak = 0;
    DateTime? prevDate;
    for (final key in sortedKeys) {
      if ((counts[key] ?? 0) <= 0) continue;
      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      if (prevDate != null && date.difference(prevDate).inDays == 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      prevDate = date;
      if (runningStreak > longestStreak) longestStreak = runningStreak;
    }

    // currentStreak: now の日から遡る連続活動日数（当日が0なら0）
    var currentStreak = 0;
    var cursor = nowDate;
    while ((counts[dateKey(cursor)] ?? 0) > 0) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return PlayActivityHeatmap(
      weeks: List.unmodifiable(resultWeeks),
      totalElections: totalElections,
      activeDays: activeDays,
      maxCount: maxCount,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      busiestDay: busiestDay,
    );
  }
}
