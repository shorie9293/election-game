import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/election_service.dart';

void main() {
  group('ElectionService.computeElectionResult', () {
    test('得票数が計算され当選者が決まる', () {
      final election = Election.sample();
      final result = ElectionService.computeElectionResult(election);

      expect(result.winnerId, isNotNull);
      expect(result.voteCounts, isNotNull);
      expect(result.voteCounts!.values.fold(0, (a, b) => a + b), 100);
    });

    test('全ての候補者が得票数を持つ', () {
      final election = Election.sample();
      final result = ElectionService.computeElectionResult(election);

      for (final candidate in election.candidates) {
        expect(result.voteCounts!.containsKey(candidate.id), true);
      }
    });
  });

  group('ElectionService.computeMoodChange', () {
    test('大差勝利でムードが上昇する（独裁方向）', () {
      final state = SocietyState.initial();
      final result = Election.sample().copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 80, 'candidate_2': 10, 'candidate_3': 10},
      );

      final newMood = ElectionService.computeMoodChange(state, result);
      expect(newMood, greaterThan(state.mood));
    });

    test('接戦でムードが下降する（健全方向）', () {
      final state = SocietyState.initial();
      // 勝者: 45% → 40%-60%の範囲で接戦扱い
      final result = Election.sample().copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 45, 'candidate_2': 30, 'candidate_3': 25},
      );

      final newMood = ElectionService.computeMoodChange(state, result);
      expect(newMood, lessThan(state.mood));
    });

    test('当選者なしの場合はムードが変わらない', () {
      final state = SocietyState.initial();
      final result = Election.sample().copyWith(
        winnerId: null,
        voteCounts: null,
      );

      final newMood = ElectionService.computeMoodChange(state, result);
      expect(newMood, state.mood);
    });
  });

  group('ElectionService.applyElectionToLife', () {
    test('当選者の公約がライフパラメータに反映される', () {
      final lifeParams = {
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 50,
        'safety': 50,
      };

      // 山田太郎（candidate_1）: employment+10, environment-5, lifeCost+3, lifeCost-10, healthcare-5
      final result = Election.sample().copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 60, 'candidate_2': 40},
      );

      final updated = ElectionService.applyElectionToLife(lifeParams, result);
      // lifeCost: 50 + (-10 + 3) = 43
      expect(updated['lifeCost'], 43);
      // employment: 50 + 10 = 60
      expect(updated['employment'], 60);
      // environment: 50 + (-5) = 45
      expect(updated['environment'], 45);
      // healthcare: 50 + (-5) = 45
      expect(updated['healthcare'], 45);
    });

    test('当選者なしの場合は変化しない', () {
      final lifeParams = {
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 50,
        'safety': 50,
      };

      final result = Election.sample().copyWith(
        winnerId: null,
        voteCounts: null,
      );

      final updated = ElectionService.applyElectionToLife(lifeParams, result);
      expect(updated, lifeParams);
    });
  });

  group('ElectionService.determineCandidates', () {
    test('ムード0.1で候補者が1人になる', () {
      final state = SocietyState(happiness: 50, mood: 0.1, electionCount: 0);
      final candidates = ElectionService.determineCandidates(state);
      expect(candidates.length, 1);
    });

    test('ムード0.3で候補者が2人になる', () {
      final state = SocietyState(happiness: 50, mood: 0.3, electionCount: 0);
      final candidates = ElectionService.determineCandidates(state);
      expect(candidates.length, 2);
    });

    test('ムード0.5で候補者が3人になる', () {
      final state = SocietyState(happiness: 50, mood: 0.5, electionCount: 0);
      final candidates = ElectionService.determineCandidates(state);
      expect(candidates.length, 3);
    });

    test('ムード0.9で候補者が1人になる', () {
      final state = SocietyState(happiness: 50, mood: 0.9, electionCount: 0);
      final candidates = ElectionService.determineCandidates(state);
      expect(candidates.length, 1);
    });
  });

  group('ElectionService.computeHappinessChange', () {
    test('自分の支持候補が当選すると幸福度が上昇する', () {
      final state = SocietyState.initial();
      final result = Election.sample().copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 60, 'candidate_2': 40},
      );

      final newHappiness = ElectionService.computeHappinessChange(
        state, result, 'candidate_1');
      expect(newHappiness, greaterThan(state.happiness));
    });

    test('自分の支持候補が落選すると幸福度が下降する', () {
      final state = SocietyState.initial();
      final result = Election.sample().copyWith(
        winnerId: 'candidate_2',
        voteCounts: {'candidate_1': 30, 'candidate_2': 70},
      );

      final newHappiness = ElectionService.computeHappinessChange(
        state, result, 'candidate_1');
      expect(newHappiness, lessThan(state.happiness));
    });
  });

  group('ElectionService.computeNextElectionTurns', () {
    test('デフォルトで10ターン後が次の選挙', () {
      final turns = ElectionService.computeNextElectionTurns();
      expect(turns, 10);
    });
  });
}
