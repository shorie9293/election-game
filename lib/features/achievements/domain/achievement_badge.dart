import 'package:equatable/equatable.dart';

import '../../../domain/models/election.dart';
import '../../../domain/models/election_scale.dart';
import '../../../domain/models/quiz_result.dart';
import '../../../domain/services/play_activity_heatmap_service.dart';

/// 実績バッジの格（達成の重み）。
///
/// ブロンズ→シルバー→ゴールド→伝説の順に難度が上がる。
enum BadgeTier {
  bronze(label: 'ブロンズ', emoji: '🥉'),
  silver(label: 'シルバー', emoji: '🥈'),
  gold(label: 'ゴールド', emoji: '🥇'),
  legend(label: '伝説', emoji: '👑');

  const BadgeTier({required this.label, required this.emoji});

  /// 日本語ラベル
  final String label;

  /// 表示用絵文字
  final String emoji;
}

/// バッジの達成条件に用いる指標。
///
/// いずれも既存の [GameState]・選挙アーカイブ・クイズ自己ベストから
/// 算出できる素材のみで構成される（新規の永続化を要さない）。
enum AchievementMetric {
  /// 実施した選挙の回数
  electionCount,

  /// 投票した候補が当選した回数
  votedWinner,

  /// 天照町への到達（0/1）
  reachedTown,

  /// 天照市への到達（0/1）
  reachedCity,

  /// クイズ自己ベストの正答数
  quizBestCorrect,

  /// クイズの累計挑戦回数
  quizAttempts,

  /// クイズ全問正解（0/1）
  quizPerfect,

  /// 選挙を実施した日数（ローカル日付の重複を除く）
  playDays,
}

/// 実績バッジの定義。
///
/// [requiredCount] は達成に必要な指標の値。不変条件は非 const コンストラクタで
/// [ArgumentError] を投げて強制する（assert は release で無効化されるため使わない）。
class AchievementBadgeDefinition extends Equatable {
  final String id;
  final String name;
  final String description;
  final BadgeTier tier;
  final int requiredCount;
  final AchievementMetric metric;

  AchievementBadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.requiredCount,
    required this.metric,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'バッジIDが空です');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'バッジ名が空です');
    }
    if (requiredCount <= 0) {
      throw ArgumentError.value(
        requiredCount,
        'requiredCount',
        '必要数は1以上でなければなりません',
      );
    }
  }

  @override
  List<Object?> get props => [id, name, description, tier, requiredCount, metric];
}

/// バッジ1件の進捗。現在値は 0 未満を 0 として扱い、[required] でクランプする。
class AchievementBadgeProgress extends Equatable {
  final AchievementBadgeDefinition definition;
  final int current;

  const AchievementBadgeProgress({
    required this.definition,
    required this.current,
  });

  int get required => definition.requiredCount;

  /// 0 未満は 0 として扱う現在値
  int get clampedCurrent => current < 0 ? 0 : current;

  /// 達成率（0.0〜1.0 にクランプ）
  double get ratio {
    if (required <= 0) return 0.0;
    final r = clampedCurrent / required;
    if (r < 0) return 0.0;
    if (r > 1) return 1.0;
    return r;
  }

  /// 達成率（0〜100 の整数）
  int get percent => (ratio * 100).round();

  bool get isComplete => clampedCurrent >= required;

  /// 獲得済みか（[isComplete] の別名）
  bool get isEarned => isComplete;

  /// 達成までの残り（達成済みは 0）
  int get remaining => isComplete ? 0 : required - clampedCurrent;

  /// 表示用の進捗（例 '3 / 5'）。required を超える値は表示しない。
  String get progressLabel =>
      '${clampedCurrent > required ? required : clampedCurrent} / $required';

  @override
  List<Object?> get props => [definition, current];
}

/// バッジ判定の入力シグナル。
///
/// 全て既存データ（[GameState] 相当の値・選挙アーカイブ・クイズ自己ベスト）
/// から構築でき、IO・現在時刻に依存しない。
class AchievementSignals extends Equatable {
  final int electionCount;
  final ElectionScale scale;
  final List<Election> pastElections;
  final QuizBestScore? quizBest;

  const AchievementSignals({
    this.electionCount = 0,
    this.scale = ElectionScale.village,
    this.pastElections = const [],
    this.quizBest,
  });

  /// 投票した候補（`voterId`）が当選者と一致した完了済み選挙の回数。
  int get votedWinnerCount {
    var count = 0;
    for (final e in pastElections) {
      final voted = e.voterId;
      if (voted == null) continue;
      if (e.completed && e.winnerId == voted) count++;
    }
    return count;
  }

  /// 選挙を実施したローカル日数（重複を除く）。
  int get playDays =>
      PlayActivityHeatmapService.countsByDate(pastElections).keys.length;

  /// 到達済みスケールか（[ElectionScale] の段階順で判定）。
  bool get reachedTown => scale.index >= ElectionScale.town.index;
  bool get reachedCity => scale.index >= ElectionScale.city.index;

  int get quizBestCorrect => quizBest?.correctCount ?? 0;
  int get quizAttempts => quizBest?.attempts ?? 0;

  /// クイズ全問正解の記録があるか（0/1）。出題数0は達成扱いにしない。
  int get quizPerfect {
    final best = quizBest;
    if (best == null || best.total <= 0) return 0;
    return best.correctCount >= best.total ? 1 : 0;
  }

  /// 指標の現在値。
  int valueOf(AchievementMetric metric) {
    switch (metric) {
      case AchievementMetric.electionCount:
        return electionCount;
      case AchievementMetric.votedWinner:
        return votedWinnerCount;
      case AchievementMetric.reachedTown:
        return reachedTown ? 1 : 0;
      case AchievementMetric.reachedCity:
        return reachedCity ? 1 : 0;
      case AchievementMetric.quizBestCorrect:
        return quizBestCorrect;
      case AchievementMetric.quizAttempts:
        return quizAttempts;
      case AchievementMetric.quizPerfect:
        return quizPerfect;
      case AchievementMetric.playDays:
        return playDays;
    }
  }

  @override
  List<Object?> get props =>
      [electionCount, scale, pastElections, quizBest];
}

/// 全バッジの進捗コレクション。
class AchievementBadgeCollection extends Equatable {
  final List<AchievementBadgeProgress> progresses;

  const AchievementBadgeCollection({required this.progresses});

  int get totalCount => progresses.length;

  int get earnedCount => progresses.where((p) => p.isEarned).length;

  double get completionRatio =>
      totalCount == 0 ? 0.0 : earnedCount / totalCount;

  /// サマリー表示（例 '獲得 7 / 14'）
  String get summaryLabel => '獲得 $earnedCount / $totalCount';

  /// 指定した格のバッジ（登録順）。
  List<AchievementBadgeProgress> byTier(BadgeTier tier) => progresses
      .where((p) => p.definition.tier == tier)
      .toList(growable: false);

  /// 未獲得のバッジ（登録順）。
  List<AchievementBadgeProgress> get unearned =>
      progresses.where((p) => !p.isEarned).toList(growable: false);

  @override
  List<Object?> get props => [progresses];
}
