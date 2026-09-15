import 'election_scale.dart';

/// 過去の選挙1回分をアーカイブ視点で要約したエントリ。
///
/// 選挙アーカイブ画面・サマリー計算の共通データとして使う。
/// 複数の選挙アーカイブを俯瞰するサマリー。
class ElectionArchiveEntry {
  /// 元選挙のID（`election_` + ミリ秒 の形式を想定）
  final String electionId;

  /// 選挙タイトル
  final String title;

  /// 選挙スケール（村/町/市）
  final ElectionScale scale;

  /// 当選者ID
  final String winnerId;

  /// 当選者名
  final String winnerName;

  /// 当選者の得票数
  final int winnerVotes;

  /// 総得票数
  final int totalVotes;

  /// 2位候補の得票数（候補1件なら0）
  final int runnerUpVotes;

  /// 選挙が行われた日時（IDから復元できない場合はnull）
  final DateTime? occurredAt;

  const ElectionArchiveEntry({
    required this.electionId,
    required this.title,
    required this.scale,
    required this.winnerId,
    required this.winnerName,
    required this.winnerVotes,
    required this.totalVotes,
    required this.runnerUpVotes,
    this.occurredAt,
  });

  /// 当選得票率（0除算ガード付き・0.0〜1.0）
  double get winnerShare => totalVotes <= 0 ? 0.0 : winnerVotes / totalVotes;

  /// 2位との得票差
  int get margin => winnerVotes - runnerUpVotes;

  /// 圧勝（得票率60%以上）か
  bool get isLandslide => winnerShare >= 0.6;

  /// スケールの日本語ラベル（村/町/市）
  String get scaleLabel {
    switch (scale) {
      case ElectionScale.village:
        return '村';
      case ElectionScale.town:
        return '町';
      case ElectionScale.city:
        return '市';
    }
  }

  List<Object?> get _props => [
        electionId,
        title,
        scale,
        winnerId,
        winnerName,
        winnerVotes,
        totalVotes,
        runnerUpVotes,
        occurredAt,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElectionArchiveEntry &&
          other.runtimeType == runtimeType &&
          _equals(other);

  bool _equals(ElectionArchiveEntry other) {
    for (var i = 0; i < _props.length; i++) {
      if (_props[i] != other._props[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}

/// 複数の選挙アーカイブを俯瞰するサマリー。
class ElectionArchiveSummary {
  /// アーカイブ済み選挙数
  final int totalCount;

  /// 当選者名ごとの当選回数（回数降順→名前昇順で並べた不変Map）
  final Map<String, int> winnerWinCounts;

  /// 当選得票率の平均（0件なら0.0）
  final double averageWinnerShare;

  /// 2位との得票差が最大の選挙（空ならnull）
  final ElectionArchiveEntry? largestMarginEntry;

  /// 2位との得票差が最小の選挙（空ならnull）
  final ElectionArchiveEntry? closestElectionEntry;

  /// スケールごとの選挙数（ElectionScale.values の順序を保持）
  final Map<ElectionScale, int> scaleCounts;

  const ElectionArchiveSummary({
    required this.totalCount,
    required this.winnerWinCounts,
    required this.averageWinnerShare,
    required this.largestMarginEntry,
    required this.closestElectionEntry,
    required this.scaleCounts,
  });

  /// winnerWinCounts を書き換え不可にしたMap
  Map<String, int> get unmodifiableWinnerWinCounts =>
      Map.unmodifiable(winnerWinCounts);

  /// scaleCounts を書き換え不可にしたMap
  Map<ElectionScale, int> get unmodifiableScaleCounts =>
      Map.unmodifiable(scaleCounts);
}