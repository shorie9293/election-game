import 'package:election_game/domain/models/citizen_enums.dart';

/// 一つの生活パラメータの時系列の1点。
class LifeParamTrendPoint {
  /// 選挙ID（`Election.id`、形式は `election_<millis>`）
  final String electionId;

  /// 選挙の発生日時
  final DateTime occurredAt;

  /// この時点の値
  final int value;

  /// 直前の点との差（最初の点は0）
  final int delta;

  const LifeParamTrendPoint({
    required this.electionId,
    required this.occurredAt,
    required this.value,
    required this.delta,
  });

  /// 差分の表示ラベル（`+3` / `-2` / `±0`）
  String get deltaLabel => _deltaLabel(delta);

  @override
  String toString() =>
      'LifeParamTrendPoint(electionId: $electionId, occurredAt: $occurredAt, '
      'value: $value, delta: $delta)';
}

/// 一つの生活パラメータキーの完全な時系列。
class LifeParamTrendSeries {
  /// 生活パラメータのキー
  final String key;

  /// 日本語ラベル（[LifeParamKeys.label]）
  final String label;

  /// 時系列ポイント（発生時刻昇順・常に非null）
  final List<LifeParamTrendPoint> points;

  const LifeParamTrendSeries({
    required this.key,
    required this.label,
    this.points = const [],
  });

  /// データが1件でもあるか
  bool get hasData => points.isNotEmpty;

  /// 最初の値（空なら null）
  int? get firstValue => points.isEmpty ? null : points.first.value;

  /// 最新の値（空なら null）
  int? get latestValue => points.isEmpty ? null : points.last.value;

  /// 最小値（空なら0）
  int get minValue {
    if (points.isEmpty) return 0;
    var min = points.first.value;
    for (final p in points) {
      if (p.value < min) min = p.value;
    }
    return min;
  }

  /// 最大値（空なら0）
  int get maxValue {
    if (points.isEmpty) return 0;
    var max = points.first.value;
    for (final p in points) {
      if (p.value > max) max = p.value;
    }
    return max;
  }

  /// 全体の変化量（最新 - 最初、空なら0）
  int get totalDelta => points.isEmpty ? 0 : points.last.value - points.first.value;

  /// 全体の変化量ラベル（`+3` / `-2` / `±0`）
  String get totalDeltaLabel => _deltaLabel(totalDelta);

  /// トレンドの方向ラベル（`上昇` / `低下` / `横ばい`）
  String get directionLabel {
    if (totalDelta > 0) return '上昇';
    if (totalDelta < 0) return '低下';
    return '横ばい';
  }
}

/// 差分の共通ラベル変換（`+3` / `-2` / `±0`）。
String _deltaLabel(int delta) {
  if (delta > 0) return '+$delta';
  if (delta < 0) return '$delta';
  return '±0';
}
