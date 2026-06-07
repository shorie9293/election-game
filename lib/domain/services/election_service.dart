import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';

/// 選挙に関わる純粋関数サービス
class ElectionService {
  ElectionService._();

  /// 選挙結果を計算
  /// 各候補者の公約効果の合計値に比例して得票数を割り振る
  static Election computeElectionResult(Election election) {
    final scores = <String, int>{};
    for (final candidate in election.candidates) {
      int totalScore = 0;
      for (final value in candidate.totalEffects.values) {
        if (value > 0) {
          totalScore += value;
        }
      }
      scores[candidate.id] = totalScore;
    }

    final totalScore = scores.values.fold<int>(0, (a, b) => a + b);
    final voteCounts = <String, int>{};
    int remainingVotes = 100;

    for (final entry in scores.entries) {
      if (entry.key == scores.entries.last.key) {
        voteCounts[entry.key] = remainingVotes;
      } else {
        final votes =
            totalScore > 0 ? (100 * entry.value ~/ totalScore) : 0;
        voteCounts[entry.key] = votes;
        remainingVotes -= votes;
      }
    }

    // 当選者を決定（最高得点）
    String? winnerId;
    int maxScore = -1;
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        winnerId = entry.key;
      }
    }

    return election.copyWith(
      voteCounts: voteCounts,
      winnerId: winnerId,
    );
  }

  /// 社会ムードの変化を計算
  static double computeMoodChange(SocietyState state, Election result) {
    if (result.winnerId == null || result.voteCounts == null) {
      return state.mood;
    }

    final winnerVotes = result.voteCounts![result.winnerId!] ?? 0;
    final totalVotes =
        result.voteCounts!.values.fold<int>(0, (a, b) => a + b);
    final winnerPercentage =
        totalVotes > 0 ? winnerVotes / totalVotes : 0.0;

    double moodChange;
    if (winnerPercentage > 0.6) {
      moodChange = 0.15; // 独裁方向
    } else if (winnerPercentage >= 0.4) {
      moodChange = -0.05; // 健全な競争
    } else {
      moodChange = 0.05; // 分裂
    }

    return (state.mood + moodChange).clamp(0.0, 1.0);
  }

  /// 幸福度の変化を計算（自分の投票した候補が当選/落選で変化）
  static double computeHappinessChange(
      SocietyState state, Election result, String votedCandidateId) {
    if (result.winnerId == null) {
      return state.happiness;
    }

    double change;
    if (result.winnerId == votedCandidateId) {
      change = 10.0; // 支持候補当選
    } else {
      change = -5.0; // 支持候補落選
    }

    return (state.happiness + change).clamp(0.0, 100.0);
  }

  /// 当選者の公約をライフパラメータに適用
  static Map<String, int> applyElectionToLife(
      Map<String, int> lifeParams, Election result) {
    if (result.winnerId == null) {
      return Map<String, int>.from(lifeParams);
    }

    final winner = result.candidates.firstWhere(
      (c) => c.id == result.winnerId,
    );

    final newLifeParams = Map<String, int>.from(lifeParams);
    for (final entry in winner.totalEffects.entries) {
      final currentValue = newLifeParams[entry.key] ?? 0;
      newLifeParams[entry.key] =
          (currentValue + entry.value).clamp(0, 100);
    }

    return newLifeParams;
  }

  /// 社会ムードに応じて立候補者を決定
  static List<Candidate> determineCandidates(SocietyState state) {
    final allCandidates = Candidate.samples();

    if (state.mood < 0.2) {
      return allCandidates.sublist(0, 1);
    } else if (state.mood < 0.4) {
      return allCandidates.sublist(0, 2);
    } else if (state.mood < 0.6) {
      return allCandidates.sublist(0, 3);
    } else if (state.mood < 0.8) {
      return allCandidates.sublist(0, 2);
    } else {
      return allCandidates.sublist(0, 1);
    }
  }

  /// 次回選挙までのターン数を計算
  static int computeNextElectionTurns() {
    return 10;
  }
}
