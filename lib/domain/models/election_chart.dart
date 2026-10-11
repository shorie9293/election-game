/// 選挙結果グラフ用の純粋ドメインモデル群。
///
/// I/O や現在時刻に依存せず、値の検証と整形ラベルのみを担う。
library;

/// グラフ上の1選挙分のプロット点。
class ElectionChartPoint {
  /// 元選挙のID
  final String electionId;

  /// グラフ用ラベル（'第1回' 等・サービスが採番する）
  final String label;

  /// 選挙が行われた日時（復元できない場合はnull）
  final DateTime? occurredAt;

  /// 当選得票率（0.0〜1.0）
  final double winnerShare;

  /// 総得票数
  final int totalVotes;

  /// 当選者名
  final String winnerName;

  /// コンストラクタ本体で値域を検証する（違反は ArgumentError）。
  ElectionChartPoint({
    required this.electionId,
    required this.label,
    this.occurredAt,
    required this.winnerShare,
    required this.totalVotes,
    required this.winnerName,
  }) {
    if (winnerShare < 0 || winnerShare > 1) {
      throw ArgumentError.value(
        winnerShare,
        'winnerShare',
        '0.0〜1.0 の範囲で指定してください',
      );
    }
    if (totalVotes < 0) {
      throw ArgumentError.value(
        totalVotes,
        'totalVotes',
        '負の値は指定できません',
      );
    }
  }

  /// 例: '52.3%'
  String get sharePercentLabel =>
      '${(winnerShare * 100).toStringAsFixed(1)}%';

  List<Object?> get _props =>
      [electionId, label, occurredAt, winnerShare, totalVotes, winnerName];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElectionChartPoint &&
          other.runtimeType == runtimeType &&
          _equals(other);

  bool _equals(ElectionChartPoint other) {
    for (var i = 0; i < _props.length; i++) {
      if (_props[i] != other._props[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}

/// 政党（派閥）ごとの時系列シェア系列。
class ElectionPartySeries {
  /// 政党（派閥）名
  final String faction;

  /// 各選挙でのシェア（0.0〜1.0・points と同じ順序・同じ長さ）
  final List<double> shares;

  /// 全選挙の平均シェア
  final double averageShare;

  /// 直近（最後）のシェア
  final double latestShare;

  /// 最高シェア
  final double peakShare;

  /// shares は [List.unmodifiable] で保持する。
  ElectionPartySeries({
    required this.faction,
    required List<double> shares,
    required this.averageShare,
    required this.latestShare,
    required this.peakShare,
  }) : shares = List.unmodifiable(shares);

  /// トレンドラベル（shares.first との差で判定・空なら'横ばい'）。
  String get trendLabel {
    if (shares.isEmpty) return '横ばい';
    final delta = latestShare - shares.first;
    if (delta > 0.01) return '上昇';
    if (delta < -0.01) return '下降';
    return '横ばい';
  }

  /// 例: '34.0%'
  String get latestPercentLabel =>
      '${(latestShare * 100).toStringAsFixed(1)}%';
}

/// 複数選挙を俯瞰する比較サマリー。
class ElectionComparison {
  /// グラフ用プロット点（時系列順）
  final List<ElectionChartPoint> points;

  /// 政党別シェア系列
  final List<ElectionPartySeries> series;

  /// 当選得票率の平均（0件なら0.0）
  final double averageWinnerShare;

  /// 最終と最初の得票率差（0件/1件は0.0）
  final double shareChange;

  /// 最高得票率の点（同値は先頭優先）
  final ElectionChartPoint? highestSharePoint;

  /// 最低得票率の点（同値は先頭優先）
  final ElectionChartPoint? lowestSharePoint;

  const ElectionComparison({
    required this.points,
    required this.series,
    required this.averageWinnerShare,
    required this.shareChange,
    required this.highestSharePoint,
    required this.lowestSharePoint,
  });

  /// アーカイブ済み選挙数
  int get totalElections => points.length;

  /// 0件か
  bool get isEmpty => points.isEmpty;

  /// 例: '+3.2pt' / '-1.0pt' / '±0.0pt'
  ///
  /// 'pt' はパーセントポイント。shareChange（0〜1の差分）を100倍して整形する。
  String get shareChangeLabel {
    final pt = shareChange * 100;
    if (pt > 0) return '+${pt.toStringAsFixed(1)}pt';
    if (pt < 0) return '${pt.toStringAsFixed(1)}pt';
    return '±0.0pt';
  }
}
