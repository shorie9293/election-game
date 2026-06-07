import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/election_service.dart';

void main() {
  group('ElectionService.computeElectionResult', () {
    test('returns voteCounts and winnerId for a sample election', () {
      final election = Election.sampleVillage();
      final result = ElectionService.computeElectionResult(election);

      expect(result.voteCounts, isNotNull);
      expect(result.winnerId, isNotNull);
      expect(result.voteCounts!.values.fold(0, (a, b) => a + b), equals(100));
      expect(result.voteCounts!.length, equals(election.candidates.length));
    });

    test('winner has the highest score', () {
      final election = Election.sampleVillage();
      final result = ElectionService.computeElectionResult(election);

      // Calculate scores manually
      final scores = <String, int>{};
      for (final candidate in election.candidates) {
        int total = 0;
        for (final policy in candidate.policies) {
          for (final value in policy.effects.values) {
            if (value > 0) total += value;
          }
        }
        scores[candidate.id] = total;
      }
      final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
      final expectedWinnerId = scores.entries
          .firstWhere((e) => e.value == maxScore)
          .key;

      expect(result.winnerId, equals(expectedWinnerId));
    });
  });

  group('ElectionService.computeMoodChange', () {
    Election electionWithWinnerVotes(int winnerVotes) {
      return Election(
        id: 'test',
        title: 'Test',
        scale: 'village',
        candidates: Candidate.samples().sublist(0, 2),
        voteCounts: {'candidate_1': winnerVotes, 'candidate_2': 100 - winnerVotes},
        winnerId: 'candidate_1',
      );
    }

    test('winner > 60% increases mood by 0.15', () {
      final state = SocietyState.initial();
      final result = electionWithWinnerVotes(70);
      final newMood = ElectionService.computeMoodChange(state, result);

      expect(newMood, closeTo(state.mood + 0.15, 0.001));
    });

    test('winner 40-60% decreases mood by 0.05', () {
      final state = SocietyState.initial();
      final result = electionWithWinnerVotes(50);
      final newMood = ElectionService.computeMoodChange(state, result);

      expect(newMood, closeTo(state.mood - 0.05, 0.001));
    });

    test('winner < 40% increases mood by 0.05', () {
      final state = SocietyState.initial();
      final result = electionWithWinnerVotes(30);
      final newMood = ElectionService.computeMoodChange(state, result);

      expect(newMood, closeTo(state.mood + 0.05, 0.001));
    });

    test('no election result returns mood unchanged', () {
      final state = SocietyState.initial();
      final election = Election.sampleVillage(); // No voteCounts or winnerId
      final newMood = ElectionService.computeMoodChange(state, election);

      expect(newMood, equals(state.mood));
    });

    test('mood is clamped to [0.0, 1.0]', () {
      // Test clamp min
      final lowMoodState = SocietyState(
        happiness: 50,
        mood: 0.01,
        electionCount: 0,
      );
      final result = electionWithWinnerVotes(50);
      final newMood = ElectionService.computeMoodChange(lowMoodState, result);

      expect(newMood, greaterThanOrEqualTo(0.0));
      expect(newMood, lessThanOrEqualTo(1.0));

      // Test clamp max
      final highMoodState = SocietyState(
        happiness: 50,
        mood: 0.95,
        electionCount: 0,
      );
      final result2 = electionWithWinnerVotes(70);
      final newMood2 = ElectionService.computeMoodChange(highMoodState, result2);

      expect(newMood2, greaterThanOrEqualTo(0.0));
      expect(newMood2, lessThanOrEqualTo(1.0));
    });
  });

  group('ElectionService.applyElectionToLife', () {
    test('applies winning candidate policy effects to lifeParams', () {
      final election = Election.sampleVillage();
      final result = ElectionService.computeElectionResult(election);

      final initialLifeParams = <String, int>{
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 50,
        'safety': 50,
      };

      final newLifeParams =
          ElectionService.applyElectionToLife(initialLifeParams, result);

      // Find winner and sum their effects
      final winner =
          result.candidates.firstWhere((c) => c.id == result.winnerId);
      final totalEffects = <String, int>{};
      for (final policy in winner.policies) {
        for (final entry in policy.effects.entries) {
          totalEffects[entry.key] =
              (totalEffects[entry.key] ?? 0) + entry.value;
        }
      }

      // Verify each effect was applied
      for (final entry in totalEffects.entries) {
        final expectedValue =
            (initialLifeParams[entry.key]! + entry.value).clamp(0, 100);
        expect(newLifeParams[entry.key], equals(expectedValue),
            reason: 'Mismatch for ${entry.key}');
      }

      // Verify unchanged params are still the same
      expect(newLifeParams.length, equals(initialLifeParams.length));
    });

    test('values are clamped to [0, 100]', () {
      final election = Election(
        id: 'test',
        title: 'Test',
        scale: 'village',
        candidates: [
          Candidate(
            id: 'candidate_1',
            name: 'Test',
            faction: 'Test',
            personality: 'Test',
            policies: [
              // Effects that would push beyond bounds
              Policy(
                title: 'Test',
                description: 'Test',
                category: 'test',
                effects: {'lifeCost': -100, 'healthcare': 200},
              ),
            ],
          ),
        ],
        voteCounts: {'candidate_1': 100},
        winnerId: 'candidate_1',
      );

      final initialLifeParams = <String, int>{
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 50,
        'safety': 50,
      };

      final newLifeParams =
          ElectionService.applyElectionToLife(initialLifeParams, election);

      expect(newLifeParams['lifeCost'], equals(0));
      expect(newLifeParams['healthcare'], equals(100));
    });

    test('no winner returns unchanged lifeParams', () {
      final election = Election.sampleVillage();
      // No winner set
      final initialLifeParams = <String, int>{
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 50,
        'safety': 50,
      };

      final newLifeParams =
          ElectionService.applyElectionToLife(initialLifeParams, election);

      expect(newLifeParams, equals(initialLifeParams));
    });
  });

  group('ElectionService.determineCandidates', () {
    test('mood < 0.2 returns 1 candidate (なれ合い)', () {
      final state = SocietyState(
        happiness: 50,
        mood: 0.1,
        electionCount: 0,
      );
      final candidates = ElectionService.determineCandidates(state);

      expect(candidates.length, equals(1));
    });

    test('mood < 0.4 returns 2 candidates (融和)', () {
      final state = SocietyState(
        happiness: 50,
        mood: 0.3,
        electionCount: 0,
      );
      final candidates = ElectionService.determineCandidates(state);

      expect(candidates.length, equals(2));
    });

    test('mood < 0.6 returns 3 candidates (健全な対立)', () {
      final state = SocietyState(
        happiness: 50,
        mood: 0.5,
        electionCount: 0,
      );
      final candidates = ElectionService.determineCandidates(state);

      expect(candidates.length, equals(3));
    });

    test('mood < 0.8 returns 2 candidates (不健全な対立 - polarized)', () {
      final state = SocietyState(
        happiness: 50,
        mood: 0.7,
        electionCount: 0,
      );
      final candidates = ElectionService.determineCandidates(state);

      expect(candidates.length, equals(2));
    });

    test('mood >= 0.8 returns 1 candidate (独裁)', () {
      final state = SocietyState(
        happiness: 50,
        mood: 0.9,
        electionCount: 0,
      );
      final candidates = ElectionService.determineCandidates(state);

      expect(candidates.length, equals(1));
    });
  });
}
