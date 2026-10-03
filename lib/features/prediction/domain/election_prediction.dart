import 'package:equatable/equatable.dart';

/// 選挙結果に対するプレイヤーの予想を表すモデル。
class ElectionPrediction extends Equatable {
  final String electionId;
  final String predictedWinnerId;
  final int predictedShare;
  final int createdAt;

  /// 非constコンストラクタ（本体で検証を行うため）。
  ElectionPrediction({
    required this.electionId,
    required this.predictedWinnerId,
    required this.predictedShare,
    required this.createdAt,
  }) {
    if (electionId.trim().isEmpty) {
      throw ArgumentError('electionId must not be empty');
    }
    if (predictedWinnerId.trim().isEmpty) {
      throw ArgumentError('predictedWinnerId must not be empty');
    }
    if (predictedShare < 1 || predictedShare > 100) {
      throw ArgumentError(
        'predictedShare must be between 1 and 100: $predictedShare',
      );
    }
  }

  ElectionPrediction copyWith({
    String? electionId,
    String? predictedWinnerId,
    int? predictedShare,
    int? createdAt,
  }) {
    return ElectionPrediction(
      electionId: electionId ?? this.electionId,
      predictedWinnerId: predictedWinnerId ?? this.predictedWinnerId,
      predictedShare: predictedShare ?? this.predictedShare,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'electionId': electionId,
      'predictedWinnerId': predictedWinnerId,
      'predictedShare': predictedShare,
      'createdAt': createdAt,
    };
  }

  factory ElectionPrediction.fromJson(Map<String, dynamic> json) {
    final dynamic electionId = json['electionId'];
    final dynamic predictedWinnerId = json['predictedWinnerId'];
    final dynamic predictedShare = json['predictedShare'];
    final dynamic createdAt = json['createdAt'];
    if (electionId is! String) {
      throw const FormatException('electionId must be a String');
    }
    if (predictedWinnerId is! String) {
      throw const FormatException('predictedWinnerId must be a String');
    }
    if (predictedShare is! int) {
      throw const FormatException('predictedShare must be an int');
    }
    if (createdAt is! int) {
      throw const FormatException('createdAt must be an int');
    }
    return ElectionPrediction(
      electionId: electionId,
      predictedWinnerId: predictedWinnerId,
      predictedShare: predictedShare,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [electionId, predictedWinnerId, predictedShare, createdAt];
}

/// 予想と実際の結果の突き合わせ結果。
class PredictionOutcome extends Equatable {
  final ElectionPrediction prediction;
  final String actualWinnerId;
  final int actualShare;
  final List<String> actualRanking;

  const PredictionOutcome({
    required this.prediction,
    required this.actualWinnerId,
    required this.actualShare,
    required this.actualRanking,
  });

  /// 当選者予想が的中したか
  bool get winnerHit => prediction.predictedWinnerId == actualWinnerId;

  /// 得票率予想の誤差（ポイント）
  int get shareError => (prediction.predictedShare - actualShare).abs();

  /// 誤差が許容範囲（5ポイント以内）か
  bool get shareWithinTolerance => shareError <= 5;

  /// スコア（0..100）: 的中50点＋(50-誤差)点
  int get score => (winnerHit ? 50 : 0) + (50 - shareError).clamp(0, 50);

  /// スコアに応じた評価ラベル
  String get accuracyLabel {
    if (score >= 90) return '完璧';
    if (score >= 70) return '大当たり';
    if (score >= 50) return 'まずまず';
    if (score >= 30) return '惜しい';
    return '外れ';
  }

  @override
  List<Object?> get props =>
      [prediction, actualWinnerId, actualShare, actualRanking];
}