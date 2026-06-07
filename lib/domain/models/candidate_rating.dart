/// 候補者の評価を表すモデル
///
/// 討論会後に各候補者を1〜5の星で評価する。
class CandidateRating {
  /// 候補者ID
  final String candidateId;

  /// 候補者名（表示用）
  final String candidateName;

  /// 1〜5の星評価
  final int rating;

  /// 評価日時（Unix タイムスタンプ）
  final int ratedAt;

  const CandidateRating({
    required this.candidateId,
    required this.candidateName,
    required this.rating,
    required this.ratedAt,
  }) : assert(rating >= 1 && rating <= 5, 'rating must be between 1 and 5');

  CandidateRating copyWith({
    String? candidateId,
    String? candidateName,
    int? rating,
    int? ratedAt,
  }) {
    return CandidateRating(
      candidateId: candidateId ?? this.candidateId,
      candidateName: candidateName ?? this.candidateName,
      rating: rating ?? this.rating,
      ratedAt: ratedAt ?? this.ratedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'candidateName': candidateName,
      'rating': rating,
      'ratedAt': ratedAt,
    };
  }

  factory CandidateRating.fromJson(Map<String, dynamic> json) {
    return CandidateRating(
      candidateId: json['candidateId'] as String,
      candidateName: json['candidateName'] as String,
      rating: json['rating'] as int,
      ratedAt: json['ratedAt'] as int,
    );
  }
}
