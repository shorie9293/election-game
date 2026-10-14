import 'achievement_badge.dart';

/// 実績バッジの定義と判定を担う純粋サービス。
///
/// 副作用・IO・現在時刻への依存を一切持たない（完全な静的メソッドのみ）。
class AchievementBadgeService {
  AchievementBadgeService._();

  /// 全バッジの定義（tier 昇順・各格内は宣言順）。
  static final List<AchievementBadgeDefinition> definitions = [
    // ── ブロンズ ──
    AchievementBadgeDefinition(
      id: 'first_election',
      name: '初陣',
      description: '初めての選挙を経験する',
      tier: BadgeTier.bronze,
      requiredCount: 1,
      metric: AchievementMetric.electionCount,
    ),
    AchievementBadgeDefinition(
      id: 'vote_hit_1',
      name: '一票の的中',
      description: '投票した候補が当選する',
      tier: BadgeTier.bronze,
      requiredCount: 1,
      metric: AchievementMetric.votedWinner,
    ),
    AchievementBadgeDefinition(
      id: 'quiz_first',
      name: '初めての学び',
      description: '政策クイズに挑戦する',
      tier: BadgeTier.bronze,
      requiredCount: 1,
      metric: AchievementMetric.quizAttempts,
    ),
    AchievementBadgeDefinition(
      id: 'quiz_correct_3',
      name: '学びの芽生え',
      description: 'クイズで自己ベスト3問正解する',
      tier: BadgeTier.bronze,
      requiredCount: 3,
      metric: AchievementMetric.quizBestCorrect,
    ),

    // ── シルバー ──
    AchievementBadgeDefinition(
      id: 'election_3',
      name: '常連市民',
      description: '選挙を3回経験する',
      tier: BadgeTier.silver,
      requiredCount: 3,
      metric: AchievementMetric.electionCount,
    ),
    AchievementBadgeDefinition(
      id: 'town_reached',
      name: '町の暮らし',
      description: '天照町へと歩みを進める',
      tier: BadgeTier.silver,
      requiredCount: 1,
      metric: AchievementMetric.reachedTown,
    ),
    AchievementBadgeDefinition(
      id: 'vote_hit_3',
      name: '民意を掴む',
      description: '投票した候補が通算3回当選する',
      tier: BadgeTier.silver,
      requiredCount: 3,
      metric: AchievementMetric.votedWinner,
    ),
    AchievementBadgeDefinition(
      id: 'play_day_3',
      name: '三日の歩み',
      description: '3日間にわたり選挙を経験する',
      tier: BadgeTier.silver,
      requiredCount: 3,
      metric: AchievementMetric.playDays,
    ),

    // ── ゴールド ──
    AchievementBadgeDefinition(
      id: 'election_5',
      name: '選挙の申し子',
      description: '選挙を5回経験する',
      tier: BadgeTier.gold,
      requiredCount: 5,
      metric: AchievementMetric.electionCount,
    ),
    AchievementBadgeDefinition(
      id: 'city_reached',
      name: '市の市民',
      description: '天照市へと歩みを進める',
      tier: BadgeTier.gold,
      requiredCount: 1,
      metric: AchievementMetric.reachedCity,
    ),
    AchievementBadgeDefinition(
      id: 'quiz_correct_5',
      name: '理解の深まり',
      description: 'クイズで自己ベスト5問正解する',
      tier: BadgeTier.gold,
      requiredCount: 5,
      metric: AchievementMetric.quizBestCorrect,
    ),
    AchievementBadgeDefinition(
      id: 'quiz_attempts_5',
      name: '学びの習慣',
      description: 'クイズに通算5回挑戦する',
      tier: BadgeTier.gold,
      requiredCount: 5,
      metric: AchievementMetric.quizAttempts,
    ),

    // ── 伝説 ──
    AchievementBadgeDefinition(
      id: 'election_10',
      name: '天照の主',
      description: '選挙を10回経験する',
      tier: BadgeTier.legend,
      requiredCount: 10,
      metric: AchievementMetric.electionCount,
    ),
    AchievementBadgeDefinition(
      id: 'quiz_perfect',
      name: '選挙マスター',
      description: 'クイズで全問正解を記録する',
      tier: BadgeTier.legend,
      requiredCount: 1,
      metric: AchievementMetric.quizPerfect,
    ),
  ];

  /// シグナルから全バッジの進捗を算出する（登録順を保持・非破壊）。
  static AchievementBadgeCollection collect(AchievementSignals signals) {
    final progresses = definitions
        .map((d) => AchievementBadgeProgress(
              definition: d,
              current: signals.valueOf(d.metric),
            ))
        .toList(growable: false);
    return AchievementBadgeCollection(progresses: progresses);
  }

  /// [collect] の進捗リストのみを返す簡便版。
  static List<AchievementBadgeProgress> build(AchievementSignals signals) =>
      collect(signals).progresses;

  /// 獲得済みバッジ数。
  static int earnedCount(AchievementSignals signals) =>
      collect(signals).earnedCount;
}
