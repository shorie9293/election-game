import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';

/// 市民の意見変化ロジックを提供する純粋関数サービス
///
/// 職業×政策マッチング、公約達成度、頑固さ、支持変動を計算する。
class OpinionService {
  OpinionService._();

  /// Concern から Policy.category 文字列へのマッピング
  static const _concernToCategory = <Concern, String>{
    Concern.agriculture: '農業',
    Concern.economy: '経済',
    Concern.education: '教育',
    Concern.employment: '雇用',
    Concern.environment: '環境',
    Concern.healthcare: '医療',
    Concern.safety: '治安',
    Concern.tax: '税制',
  };

  /// Job から関連 Concern リストを取得
  static List<Concern> _jobConcerns(Job job) {
    switch (job) {
      case Job.farmer:
        return [Concern.agriculture, Concern.environment];
      case Job.fisher:
        return [Concern.environment, Concern.employment];
      case Job.carpenter:
        return [Concern.economy, Concern.employment];
      case Job.merchant:
        return [Concern.economy, Concern.tax];
      case Job.teacher:
        return [Concern.education, Concern.healthcare];
      case Job.doctor:
        return [Concern.healthcare];
      case Job.official:
        return [Concern.safety, Concern.education];
      case Job.artisan:
        return [Concern.economy, Concern.employment];
      case Job.student:
        return [Concern.education, Concern.employment];
      case Job.unemployed:
        return [Concern.employment, Concern.healthcare];
    }
  }

  /// 職業に基づいた政策親和性を計算する (0.0–1.0)
  ///
  /// [job] の関心カテゴリと [candidate] の政策カテゴリを照合し、
  /// 政策効果の合計値に対するマッチ割合を返す。
  static double computeProfessionPolicyAffinity(Job job, Candidate candidate) {
    if (candidate.policies.isEmpty) {
      return 0.5;
    }

    final jobCategories = _jobConcerns(job)
        .map((c) => _concernToCategory[c]!)
        .toSet();

    int matchingSum = 0;
    int totalSum = 0;

    for (final policy in candidate.policies) {
      final policySum = policy.effects.values.fold<int>(0, (a, b) => a + b);
      totalSum += policySum;
      if (jobCategories.contains(policy.category)) {
        matchingSum += policySum;
      }
    }

    if (totalSum == 0) {
      return 0.5;
    }

    return (matchingSum / totalSum).clamp(0.0, 1.0);
  }

  /// 現職の公約達成度を計算する (0.0–1.0)
  ///
  /// [winner] の公約効果（totalEffects）における各ライフパラメータの変化が
  /// 市民にとって改善（正の効果）か悪化（負の効果）かを評価する。
  /// 改善されたパラメータ数 / 影響を受けた全パラメータ数。
  static double computeIncumbentAchievement(
      Citizen citizen, Candidate winner) {
    final effects = winner.totalEffects;
    if (effects.isEmpty) {
      return 0.5;
    }

    int improvedCount = 0;
    int totalAffected = 0;

    for (final entry in effects.entries) {
      totalAffected++;
      if (entry.value > 0) {
        improvedCount++;
      }
    }

    if (totalAffected == 0) {
      return 0.5;
    }

    return improvedCount / totalAffected;
  }

  /// 社会ムードに基づく市民の頑固さを計算する (0.0–1.0)
  ///
  /// ムードと頑固さの対応:
  /// - 0.0–0.2 (なれ合い): 0.8 — 皆が同意しており変化に抵抗
  /// - 0.2–0.4 (融和): 0.5
  /// - 0.4–0.6 (健全な対立): 0.2 — 議論に開放的
  /// - 0.6–0.8 (不健全な対立): 0.7 — 固定化
  /// - 0.8–1.0 (独裁): 0.9 — 非常に高い頑固さ
  static double computeStubbornness(SocietyState society) {
    if (society.mood < 0.2) {
      return 0.8; // なれ合い
    } else if (society.mood < 0.4) {
      return 0.5; // 融和
    } else if (society.mood < 0.6) {
      return 0.2; // 健全な対立
    } else if (society.mood < 0.8) {
      return 0.7; // 不健全な対立
    } else {
      return 0.9; // 独裁
    }
  }

  /// 市民のある候補者に対する支持変動を計算する (0.0–1.0)
  ///
  /// [citizen] の職業親和性をベースに、[lastElection] の現職実績と
  /// [society] の頑固さを加味して最終支持率を算出する。
  ///
  /// - 前回選挙がない場合: 職業親和性をそのまま返す
  /// - 前回選挙がある場合:
  ///   1. 現職の公約達成度を計算
  ///   2. 候補者が現職か挑戦者かで加重を変える
  ///   3. 社会の頑固さで減衰
  static double computeSupportChange(
    Citizen citizen,
    Candidate candidate,
    SocietyState society,
    Election? lastElection,
  ) {
    final affinity =
        computeProfessionPolicyAffinity(citizen.job, candidate);

    if (lastElection == null || lastElection.winnerId == null) {
      return affinity.clamp(0.0, 1.0);
    }

    // 前回当選者を取得
    final winner = lastElection.candidates.firstWhere(
      (c) => c.id == lastElection.winnerId,
      orElse: () => candidate, // フォールバック（論理的には起こらない）
    );

    final achievement = computeIncumbentAchievement(citizen, winner);
    final stubbornness = computeStubbornness(society);

    double base;
    if (candidate.id == lastElection.winnerId) {
      // 現職: 親和性×0.4 + 達成度×0.6
      base = affinity * 0.4 + achievement * 0.6;
    } else {
      // 挑戦者: 親和性×0.7 + (1-達成度)×0.3
      base = affinity * 0.7 + (1 - achievement) * 0.3;
    }

    final result = base * (1 - stubbornness * 0.5);
    return result.clamp(0.0, 1.0);
  }
}
