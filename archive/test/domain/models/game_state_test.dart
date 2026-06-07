import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/candidate.dart';

void main() {
  group('GameState', () {
    final testCitizen = Citizen.initial(Job.farmer);
    final testSociety = SocietyState.initial();
    final testElection = Election.sampleVillage();

    group('constructor', () {
      test('creates a GameState with required fields', () {
        final state = GameState(
          citizen: testCitizen,
          society: testSociety,
        );

        expect(state.citizen, equals(testCitizen));
        expect(state.society, equals(testSociety));
        expect(state.currentElection, isNull);
        expect(state.pastElections, isEmpty);
      });

      test('creates a GameState with current election', () {
        final state = GameState(
          citizen: testCitizen,
          society: testSociety,
          currentElection: testElection,
        );

        expect(state.currentElection, equals(testElection));
      });

      test('creates a GameState with past elections', () {
        final state = GameState(
          citizen: testCitizen,
          society: testSociety,
          pastElections: [testElection],
        );

        expect(state.pastElections.length, 1);
        expect(state.pastElections[0], equals(testElection));
      });
    });

    group('Equatable', () {
      test('two identical states are equal', () {
        final s1 = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final s2 = GameState(
          citizen: testCitizen,
          society: testSociety,
        );

        expect(s1, equals(s2));
      });

      test('states with different citizens are not equal', () {
        final s1 = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final s2 = GameState(
          citizen: Citizen.initial(Job.doctor),
          society: testSociety,
        );

        expect(s1, isNot(equals(s2)));
      });

      test('states with different societies are not equal', () {
        final s1 = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final s2 = GameState(
          citizen: testCitizen,
          society: testSociety.copyWith(happiness: 80.0),
        );

        expect(s1, isNot(equals(s2)));
      });

      test('states with different currentElection are not equal', () {
        final s1 = GameState(
          citizen: testCitizen,
          society: testSociety,
          currentElection: testElection,
        );
        final s2 = GameState(
          citizen: testCitizen,
          society: testSociety,
        );

        expect(s1, isNot(equals(s2)));
      });

      test('states with different pastElections are not equal', () {
        final s1 = GameState(
          citizen: testCitizen,
          society: testSociety,
          pastElections: [testElection],
        );
        final s2 = GameState(
          citizen: testCitizen,
          society: testSociety,
        );

        expect(s1, isNot(equals(s2)));
      });
    });

    group('toJson / fromJson roundtrip', () {
      test('roundtrips a state with no election', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final json = original.toJson();
        final restored = GameState.fromJson(json);

        expect(restored, equals(original));
        expect(restored.currentElection, isNull);
        expect(restored.pastElections, isEmpty);
      });

      test('roundtrips a state with current election', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
          currentElection: testElection,
        );
        final json = original.toJson();
        final restored = GameState.fromJson(json);

        expect(restored, equals(original));
        expect(restored.currentElection, isNotNull);
        expect(restored.currentElection!.id, 'election_1');
      });

      test('roundtrips a state with current election and past elections', () {
        final pastElection = Election(
          id: 'election_0',
          title: '前回の選挙',
          scale: 'village',
          candidates: Candidate.samples(),
          voteCounts: {'candidate_1': 200, 'candidate_2': 150},
          winnerId: 'candidate_1',
        );
        final original = GameState(
          citizen: Citizen.initial(Job.doctor),
          society: SocietyState(
            happiness: 60.0,
            mood: 0.5,
            currentLeaderId: 'candidate_1',
            electionCount: 1,
          ),
          currentElection: testElection,
          pastElections: [pastElection],
        );
        final json = original.toJson();
        final restored = GameState.fromJson(json);

        expect(restored, equals(original));
        expect(restored.citizen.job, Job.doctor);
        expect(restored.society.happiness, 60.0);
        expect(restored.society.mood, 0.5);
        expect(restored.society.currentLeaderId, 'candidate_1');
        expect(restored.society.electionCount, 1);
        expect(restored.currentElection!.id, 'election_1');
        expect(restored.pastElections.length, 1);
        expect(restored.pastElections[0].id, 'election_0');
        expect(restored.pastElections[0].winnerId, 'candidate_1');
      });
    });

    group('copyWith', () {
      test('updates citizen', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final newCitizen = Citizen.initial(Job.doctor);
        final updated = original.copyWith(citizen: newCitizen);

        expect(updated.citizen, newCitizen);
        expect(updated.society, original.society);
      });

      test('updates society', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final newSociety = testSociety.copyWith(happiness: 90.0);
        final updated = original.copyWith(society: newSociety);

        expect(updated.society.happiness, 90.0);
        expect(updated.citizen, original.citizen);
      });

      test('updates currentElection', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final updated = original.copyWith(currentElection: testElection);

        expect(updated.currentElection, testElection);
      });

      test('clears currentElection with clearCurrentElection flag', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
          currentElection: testElection,
        );
        final updated = original.copyWith(clearCurrentElection: true);

        expect(updated.currentElection, isNull);
      });

      test('updates pastElections', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        final updated = original.copyWith(pastElections: [testElection]);

        expect(updated.pastElections.length, 1);
        expect(updated.pastElections[0], testElection);
      });

      test('returns same if no args', () {
        final original = GameState(
          citizen: testCitizen,
          society: testSociety,
        );
        expect(original.copyWith(), equals(original));
      });
    });

    group('props', () {
      test('contains all fields', () {
        final state = GameState(
          citizen: testCitizen,
          society: testSociety,
          currentElection: testElection,
          pastElections: [testElection],
        );

        expect(state.props.length, 4);
        expect(state.props[0], isA<Citizen>());
        expect(state.props[1], isA<SocietyState>());
        expect(state.props[2], isA<Election>());
        expect(state.props[3], isA<List<Election>>());
      });
    });
  });
}
