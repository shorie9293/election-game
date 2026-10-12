import 'package:equatable/equatable.dart';

/// 1日分の選挙プレイ活動量。date はローカル日付（時分秒は0に正規化）。
class PlayActivityDay extends Equatable {
  final DateTime date;
  final int count;

  const PlayActivityDay({required this.date, required this.count});

  bool get isActive => count > 0;

  @override
  List<Object?> get props => [date, count];
}

/// ヒートマップの1週（7日・日曜始まり）。days は常に7件。
class PlayActivityWeek extends Equatable {
  final List<PlayActivityDay> days;

  const PlayActivityWeek({required this.days});

  @override
  List<Object?> get props => [days];
}

/// 選挙プレイ活動のヒートマップ集計（不変・全フィールド public）。
class PlayActivityHeatmap extends Equatable {
  final List<PlayActivityWeek> weeks; // 古い週→新しい週
  final int totalElections; // 集計対象の全選挙回数
  final int activeDays; // 選挙を実施した日数
  final int maxCount; // 1日の最大実施回数
  final int currentStreak; // now の日から遡る連続活動日数
  final int longestStreak; // 最長の連続活動日数
  final PlayActivityDay? busiestDay; // 最多実施日（同数なら日付昇順で最初）

  const PlayActivityHeatmap({
    required this.weeks,
    required this.totalElections,
    required this.activeDays,
    required this.maxCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.busiestDay,
  });

  bool get isEmpty => totalElections == 0;

  @override
  List<Object?> get props => [
        weeks,
        totalElections,
        activeDays,
        maxCount,
        currentStreak,
        longestStreak,
        busiestDay,
      ];
}
