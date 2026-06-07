import 'package:equatable/equatable.dart';

/// 政治団体モデル
class PoliticalGroup extends Equatable {
  final String id;
  final String name;
  final String ideology;
  final double economicAxis; // -1.0(規制強化)〜+1.0(自由市場)
  final double welfareAxis; // -1.0(自己責任)〜+1.0(社会保障重視)
  final List<String> supportedCandidateIds;

  const PoliticalGroup({
    required this.id,
    required this.name,
    required this.ideology,
    required this.economicAxis,
    required this.welfareAxis,
    required this.supportedCandidateIds,
  });

  static List<PoliticalGroup> samples() {
    return [
      PoliticalGroup(
        id: 'group_development',
        name: '発展の会',
        ideology: '経済成長で皆が豊かに',
        economicAxis: 0.8,
        welfareAxis: -0.2,
        supportedCandidateIds: ['candidate_1', 'candidate_2'],
      ),
      PoliticalGroup(
        id: 'group_symbiosis',
        name: '共生の会',
        ideology: '支え合う社会を',
        economicAxis: -0.3,
        welfareAxis: 0.9,
        supportedCandidateIds: ['candidate_2'],
      ),
      PoliticalGroup(
        id: 'group_defense',
        name: '守りの会',
        ideology: '伝統と安定を守る',
        economicAxis: -0.5,
        welfareAxis: 0.0,
        supportedCandidateIds: ['candidate_3'],
      ),
      PoliticalGroup(
        id: 'group_green',
        name: '緑の会',
        ideology: '自然との調和',
        economicAxis: -0.6,
        welfareAxis: 0.4,
        supportedCandidateIds: [],
      ),
      PoliticalGroup(
        id: 'group_reform',
        name: '改革の会',
        ideology: '若者の声を政治に',
        economicAxis: 0.2,
        welfareAxis: 0.3,
        supportedCandidateIds: ['candidate_4'],
      ),
    ];
  }

  PoliticalGroup copyWith({
    String? id,
    String? name,
    String? ideology,
    double? economicAxis,
    double? welfareAxis,
    List<String>? supportedCandidateIds,
  }) {
    return PoliticalGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      ideology: ideology ?? this.ideology,
      economicAxis: economicAxis ?? this.economicAxis,
      welfareAxis: welfareAxis ?? this.welfareAxis,
      supportedCandidateIds:
          supportedCandidateIds ?? this.supportedCandidateIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ideology': ideology,
      'economicAxis': economicAxis,
      'welfareAxis': welfareAxis,
      'supportedCandidateIds': supportedCandidateIds,
    };
  }

  factory PoliticalGroup.fromJson(Map<String, dynamic> json) {
    return PoliticalGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      ideology: json['ideology'] as String,
      economicAxis: (json['economicAxis'] as num).toDouble(),
      welfareAxis: (json['welfareAxis'] as num).toDouble(),
      supportedCandidateIds:
          List<String>.from(json['supportedCandidateIds'] as List),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, ideology, economicAxis, welfareAxis, supportedCandidateIds];
}

/// 政治団体の検索ヘルパー
class PoliticalGroups {
  PoliticalGroups._();

  /// 候補者IDから所属団体を取得
  static PoliticalGroup? fromCandidateId(String candidateId) {
    for (final group in PoliticalGroup.samples()) {
      if (group.supportedCandidateIds.contains(candidateId)) {
        return group;
      }
    }
    return null;
  }
}
