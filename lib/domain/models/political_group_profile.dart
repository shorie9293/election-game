import 'package:equatable/equatable.dart';

import 'candidate.dart';
import 'political_group.dart';

/// 政治団体を可視化用に整理したプロフィール
class PoliticalGroupProfile extends Equatable {
  final PoliticalGroup group;
  final String economicLabel;
  final String welfareLabel;
  final String quadrantLabel;
  final List<Candidate> supportedCandidates;

  const PoliticalGroupProfile({
    required this.group,
    required this.economicLabel,
    required this.welfareLabel,
    required this.quadrantLabel,
    required this.supportedCandidates,
  });

  int get supportCount => supportedCandidates.length;

  bool get hasSupport => supportCount > 0;

  String get supportedNamesLabel => hasSupport
      ? supportedCandidates.map((c) => c.name).join('、')
      : '推薦候補なし';

  @override
  List<Object?> get props => [
        group,
        economicLabel,
        welfareLabel,
        quadrantLabel,
        supportedCandidates,
      ];
}

/// 候補者ごとの支持団体まとめ
class CandidateSupport extends Equatable {
  final Candidate candidate;
  final List<PoliticalGroup> groups;

  const CandidateSupport({required this.candidate, required this.groups});

  int get groupCount => groups.length;

  String get groupNamesLabel => groups.map((g) => g.name).join('、');

  @override
  List<Object?> get props => [candidate, groups];
}

/// 政治団体全体の分析結果
class PoliticalGroupAnalysis extends Equatable {
  final List<PoliticalGroupProfile> profiles;
  final List<CandidateSupport> candidateSupports;
  final List<PoliticalGroup> zeroSupportGroups;

  const PoliticalGroupAnalysis({
    required this.profiles,
    required this.candidateSupports,
    required this.zeroSupportGroups,
  });

  int get totalGroups => profiles.length;

  int get totalSupportEdges => profiles.fold(
        0,
        (sum, p) => sum + p.supportCount,
      );

  List<PoliticalGroupProfile> get withSupport =>
      profiles.where((p) => p.hasSupport).toList();

  @override
  List<Object?> get props => [profiles, candidateSupports, zeroSupportGroups];
}
