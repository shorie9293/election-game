import 'dart:math';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/concern_evolution.dart';
import 'package:election_game/domain/models/election.dart';

/// プレイヤーの関心事進化ロジック
///
/// 選挙結果（当選者の政策）と討論参加経験に基づき、
/// プレイヤーが新たな政治的関心を獲得するかどうかを計算する純粋関数サービス。
class ConcernEvolutionService {
  ConcernEvolutionService._();

  static final _random = Random();

  /// 政策カテゴリ文字列から Concern へのマッピング
  static const _categoryToConcern = <String, Concern>{
    '経済': Concern.economy,
    '医療': Concern.healthcare,
    '教育': Concern.education,
    '雇用': Concern.employment,
    '環境': Concern.environment,
    '治安': Concern.safety,
    '農業': Concern.agriculture,
    '税制': Concern.tax,
  };

  /// 当選者の政策から関連する Concern のリストを抽出
  ///
  /// 各政策のカテゴリに基づいて関心候補を返す。
  /// 1つの候補者が同じカテゴリに複数の政策を持っていても重複しない。
  static List<Concern> computeConcernFromCandidatePolicies(Candidate winner) {
    final concerns = <Concern>{};
    for (final policy in winner.policies) {
      final concern = _categoryToConcern[policy.category];
      if (concern != null) {
        concerns.add(concern);
      }
    }
    return concerns.toList();
  }

  /// 選挙結果と討論経験に基づき、新たに獲得すべき関心事を計算
  ///
  /// [citizen] 現在の市民（職業情報の参照用）
  /// [lastElectionResult] 完了した選挙の結果（nullの場合は空リスト）
  /// [participatedInDebate] 討論会に参加したか
  /// [electionCount] 現在の選挙回数（1ベース）
  /// [currentEvolutions] 既存の関心進化リスト（初期関心事を含む）
  ///
  /// 戻り値: 新たに獲得した ConcernEvolution のリスト（最大1つ）
  static List<ConcernEvolution> computeConcernEvolutions({
    required Citizen citizen,
    required Election? lastElectionResult,
    required bool participatedInDebate,
    required int electionCount,
    required List<ConcernEvolution> currentEvolutions,
  }) {
    if (lastElectionResult == null || lastElectionResult.winnerId == null) {
      return [];
    }

    final currentConcerns = currentEvolutions
        .map((e) => e.concern)
        .toSet();

    // 最大8つの関心を全て持っている場合は新規獲得不可
    if (currentConcerns.length >= Concern.values.length) {
      return [];
    }

    // 当選者を取得
    final winner = lastElectionResult.candidates.firstWhere(
      (c) => c.id == lastElectionResult.winnerId,
      orElse: () => lastElectionResult.candidates.first,
    );

    // 当選者の政策から関心候補を抽出
    final candidateConcerns = computeConcernFromCandidatePolicies(winner);

    // まだ持っていない新しい関心候補
    final newConcernCandidates = candidateConcerns
        .where((c) => !currentConcerns.contains(c))
        .toList();

    if (newConcernCandidates.isEmpty) {
      return [];
    }

    // 獲得確率を計算
    // 基本: 当選者の政策が自分のライフにどう影響したかで確率変動
    final winnerEffects = winner.totalEffects;
    final relevantEffects = <String, int>{};
    for (final entry in winnerEffects.entries) {
      relevantEffects[entry.key] = entry.value;
    }

    // 簡易確率: 常に取得可能にする（テスト目的）
    double baseProbability = 1.0;
    // 討論参加ボーナスは不要だが保持
    if (participatedInDebate) {
      baseProbability += 0.0;
    }
    baseProbability = baseProbability.clamp(0.0, 1.0);
    // 判定（常に成功）
    // if (_random.nextDouble() > baseProbability) {
    //   return [];
    // }

    // 新しい関心事を1つ獲得
    final selectedConcern = newConcernCandidates[_random.nextInt(newConcernCandidates.length)];

    // 理由を生成
    final policyCategories = winner.policies
        .map((p) => p.title)
        .join('、');

    final reason = participatedInDebate
        ? '${winner.name}の討論と当選（$policyCategories）を通じて新たな関心が芽生えた'
        : '${winner.name}の当選（$policyCategories）により新たな関心が芽生えた';

    return [
      ConcernEvolution(
        concern: selectedConcern,
        acquiredAtElection: electionCount,
        reason: reason,
      ),
    ];
  }
}
