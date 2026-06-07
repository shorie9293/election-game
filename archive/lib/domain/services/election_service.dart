import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';

class ElectionService {
  ElectionService._();

  /// Simulates voting based on policies' total positive effects.
  /// Each candidate gets a score = sum of all positive effect values across their policies.
  /// Vote counts are assigned proportionally out of 100 total votes.
  static Election computeElectionResult(Election election) {
    final scores = <String, int>{};
    for (final candidate in election.candidates) {
      int totalScore = 0;
      for (final policy in candidate.policies) {
        for (final value in policy.effects.values) {
          if (value > 0) {
            totalScore += value;
          }
        }
      }
      scores[candidate.id] = totalScore;
    }

    final totalScore = scores.values.fold<int>(0, (a, b) => a + b);
    final voteCounts = <String, int>{};
    int remainingVotes = 100;

    // Assign proportional votes
    for (final entry in scores.entries) {
      if (entry.key == scores.entries.last.key) {
        // Last candidate gets remaining votes
        voteCounts[entry.key] = remainingVotes;
      } else {
        final votes =
            totalScore > 0 ? (100 * entry.value ~/ totalScore) : 0;
        voteCounts[entry.key] = votes;
        remainingVotes -= votes;
      }
    }

    // Determine winner (highest score)
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

  /// Computes mood change based on election result.
  /// Returns the new mood value clamped to [0.0, 1.0].
  static double computeMoodChange(SocietyState state, Election result) {
    if (result.winnerId == null || result.voteCounts == null) {
      return state.mood;
    }

    final winnerVotes = result.voteCounts![result.winnerId!] ?? 0;
    final totalVotes = result.voteCounts!.values.fold<int>(0, (a, b) => a + b);
    final winnerPercentage = totalVotes > 0 ? winnerVotes / totalVotes : 0.0;

    double moodChange;
    if (winnerPercentage > 0.6) {
      moodChange = 0.15; // Toward dictatorship
    } else if (winnerPercentage >= 0.4) {
      moodChange = -0.05; // Healthy competition
    } else {
      moodChange = 0.05; // Fragmented
    }

    final newMood = (state.mood + moodChange).clamp(0.0, 1.0);
    return newMood;
  }

  /// Applies winning candidate's policies to life parameters.
  /// Returns a new map with values clamped to [0, 100].
  static Map<String, int> applyElectionToLife(
      Map<String, int> lifeParams, Election result) {
    if (result.winnerId == null) {
      return Map<String, int>.from(lifeParams);
    }

    final winner = result.candidates.firstWhere(
      (c) => c.id == result.winnerId,
    );

    // Sum up all effects from winner's policies
    final totalEffects = <String, int>{};
    for (final policy in winner.policies) {
      for (final entry in policy.effects.entries) {
        totalEffects[entry.key] =
            (totalEffects[entry.key] ?? 0) + entry.value;
      }
    }

    // Apply effects to lifeParams
    final newLifeParams = Map<String, int>.from(lifeParams);
    for (final entry in totalEffects.entries) {
      final currentValue = newLifeParams[entry.key] ?? 0;
      newLifeParams[entry.key] =
          (currentValue + entry.value).clamp(0, 100);
    }

    return newLifeParams;
  }

  /// Determines which candidates appear based on society mood.
  static List<Candidate> determineCandidates(SocietyState state) {
    final allCandidates = Candidate.samples();

    if (state.mood < 0.2) {
      // なれ合い: only 1 candidate
      return allCandidates.sublist(0, 1);
    } else if (state.mood < 0.4) {
      // 融和: first 2 candidates
      return allCandidates.sublist(0, 2);
    } else if (state.mood < 0.6) {
      // 健全な対立: first 3 candidates
      return allCandidates.sublist(0, 3);
    } else if (state.mood < 0.8) {
      // 不健全な対立: first 2 candidates (polarized)
      return allCandidates.sublist(0, 2);
    } else {
      // 独裁: first 1 candidate
      return allCandidates.sublist(0, 1);
    }
  }
}
