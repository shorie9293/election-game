import 'package:equatable/equatable.dart';

import 'package:election_game/domain/models/candidate.dart';

/// 候補者の効果を要約した値オブジェクト
///
/// lifeParamKey（[EffectSummary.key]）と日本語ラベル（[EffectSummary.label]）、
/// 合算値（[EffectSummary.value]）を保持する。
class EffectSummary extends Equatable {
  /// lifeParamKey（例: 'lifeCost'）
  final String key;

  /// 日本語ラベル（例: '生活費'）
  final String label;

  /// 全公約の効果を合算した値
  final int value;

  const EffectSummary({
    required this.key,
    required this.label,
    required this.value,
  });

  /// 表示用文字列（正は '+10'、負は '-5'、ゼロは '±0'）
  String get display {
    if (value > 0) return '+$value';
    if (value < 0) return '$value';
    return '±0';
  }

  @override
  List<Object?> get props => [key, label, value];
}

/// 候補者名鑑用の要約プロファイル
///
/// 候補者そのものと、名鑑表示に必要な派生値（効果一覧・得意分野）を保持する。
class CandidateProfile extends Equatable {
  /// 元となる候補者
  final Candidate candidate;

  /// 効果一覧（|value| 降順 → label 昇順の同順位。value が 0 のものも含む）
  final List<EffectSummary> effects;

  /// 公約カテゴリの最頻値（同数は初出順。公約 0 件なら ''）
  final String dominantCategory;

  const CandidateProfile({
    required this.candidate,
    required this.effects,
    required this.dominantCategory,
  });

  /// 公約の件数
  int get policyCount => candidate.policies.length;

  /// 全効果値の合計（負にもなり得る）
  int get totalEffectScore {
    return candidate.totalEffects.values.fold<int>(0, (a, b) => a + b);
  }

  /// 公約を 1 件でも持つか
  bool get hasPolicies => policyCount > 0;

  @override
  List<Object?> get props => [candidate, effects, dominantCategory];
}
