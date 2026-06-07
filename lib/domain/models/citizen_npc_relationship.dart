import 'package:equatable/equatable.dart';

/// NPCとの関係値を表すモデル
///
/// プレイヤーと各NPCの対話履歴を追跡し、
/// 関係値（-1.0〜1.0）と対話回数を管理する。
///
/// 関係値の目安:
/// - 1.0: 非常に親しい（味方）
/// - 0.5: 友好的
/// - 0.0: 中立（初対面のデフォルト）
/// - -0.5: 敵対的
/// - -1.0: 非常に敵対的（敵）
class CitizenNpcRelationship extends Equatable {
  /// NPCの識別子
  final String npcId;

  /// 関係値（-1.0 〜 1.0）
  final double relationship;

  /// 対話回数
  final int interactionCount;

  const CitizenNpcRelationship({
    required this.npcId,
    required this.relationship,
    required this.interactionCount,
  })  : assert(relationship >= -1.0 && relationship <= 1.0,
            'relationshipは-1.0〜1.0の範囲である必要があります'),
        assert(interactionCount >= 0,
            'interactionCountは0以上である必要があります');

  /// NPCとの初回関係値を生成
  factory CitizenNpcRelationship.initial(String npcId) {
    return CitizenNpcRelationship(
      npcId: npcId,
      relationship: 0.0,
      interactionCount: 0,
    );
  }

  /// 対話を記録し、関係値を更新
  ///
  /// [impact] が正なら関係値上昇、負なら低下。
  /// デフォルトは +0.05（軽い好意上昇）。
  CitizenNpcRelationship recordInteraction({double impact = 0.05}) {
    final newRelationship =
        (relationship + impact).clamp(-1.0, 1.0);
    return CitizenNpcRelationship(
      npcId: npcId,
      relationship: double.parse(newRelationship.toStringAsFixed(4)),
      interactionCount: interactionCount + 1,
    );
  }

  /// 友好的か（関係値 > 0.5）
  bool get isFriendly => relationship > 0.5;

  /// 敵対的か（関係値 < -0.5）
  bool get isHostile => relationship < -0.5;

  /// 中立か（-0.5 <= 関係値 <= 0.5）
  bool get isNeutral => !isFriendly && !isHostile;

  /// 関係値の段階を文字列で返す
  String get relationshipTier {
    if (relationship > 0.7) return 'friendly';
    if (relationship > 0.3) return 'warm';
    if (relationship >= -0.3) return 'neutral';
    if (relationship >= -0.7) return 'cold';
    return 'hostile';
  }

  CitizenNpcRelationship copyWith({
    String? npcId,
    double? relationship,
    int? interactionCount,
  }) {
    return CitizenNpcRelationship(
      npcId: npcId ?? this.npcId,
      relationship: relationship ?? this.relationship,
      interactionCount: interactionCount ?? this.interactionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'npcId': npcId,
      'relationship': relationship,
      'interactionCount': interactionCount,
    };
  }

  factory CitizenNpcRelationship.fromJson(Map<String, dynamic> json) {
    return CitizenNpcRelationship(
      npcId: json['npcId'] as String,
      relationship: (json['relationship'] as num).toDouble(),
      interactionCount: json['interactionCount'] as int,
    );
  }

  @override
  List<Object?> get props => [npcId, relationship, interactionCount];
}
