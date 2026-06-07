import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/society_state.dart';

void main() {
  group('SocietyState', () {
    group('SocietyState.initial()', () {
      test('creates with correct default values', () {
        final state = SocietyState.initial();

        expect(state.happiness, 50.0);
        expect(state.mood, 0.3);
        expect(state.currentLeaderId, isNull);
        expect(state.electionCount, 0);
      });
    });

    group('moodLabel', () {
      test('returns なれ合い for mood < 0.2', () {
        final state = SocietyState.initial().copyWith(mood: 0.19);
        expect(state.moodLabel, 'なれ合い');

        final state2 = SocietyState.initial().copyWith(mood: 0.0);
        expect(state2.moodLabel, 'なれ合い');

        final state3 = SocietyState.initial().copyWith(mood: 0.1);
        expect(state3.moodLabel, 'なれ合い');
      });

      test('returns 融和 for 0.2 <= mood < 0.4', () {
        final state = SocietyState.initial().copyWith(mood: 0.2);
        expect(state.moodLabel, '融和');

        final state2 = SocietyState.initial().copyWith(mood: 0.3);
        expect(state2.moodLabel, '融和');

        final state3 = SocietyState.initial().copyWith(mood: 0.39);
        expect(state3.moodLabel, '融和');
      });

      test('returns 健全な対立 for 0.4 <= mood < 0.6', () {
        final state = SocietyState.initial().copyWith(mood: 0.4);
        expect(state.moodLabel, '健全な対立');

        final state2 = SocietyState.initial().copyWith(mood: 0.5);
        expect(state2.moodLabel, '健全な対立');

        final state3 = SocietyState.initial().copyWith(mood: 0.59);
        expect(state3.moodLabel, '健全な対立');
      });

      test('returns 不健全な対立 for 0.6 <= mood < 0.8', () {
        final state = SocietyState.initial().copyWith(mood: 0.6);
        expect(state.moodLabel, '不健全な対立');

        final state2 = SocietyState.initial().copyWith(mood: 0.7);
        expect(state2.moodLabel, '不健全な対立');

        final state3 = SocietyState.initial().copyWith(mood: 0.79);
        expect(state3.moodLabel, '不健全な対立');
      });

      test('returns 独裁 for mood >= 0.8', () {
        final state = SocietyState.initial().copyWith(mood: 0.8);
        expect(state.moodLabel, '独裁');

        final state2 = SocietyState.initial().copyWith(mood: 0.9);
        expect(state2.moodLabel, '独裁');

        final state3 = SocietyState.initial().copyWith(mood: 1.0);
        expect(state3.moodLabel, '独裁');
      });

      test('initial mood 0.3 returns 融和', () {
        expect(SocietyState.initial().moodLabel, '融和');
      });
    });

    group('Equatable', () {
      test('two identical states are equal', () {
        final s1 = SocietyState.initial();
        final s2 = SocietyState.initial();

        expect(s1, equals(s2));
      });

      test('states with different happiness are not equal', () {
        final s1 = SocietyState.initial();
        final s2 = SocietyState.initial().copyWith(happiness: 60.0);

        expect(s1, isNot(equals(s2)));
      });

      test('states with different mood are not equal', () {
        final s1 = SocietyState.initial();
        final s2 = SocietyState.initial().copyWith(mood: 0.5);

        expect(s1, isNot(equals(s2)));
      });

      test('states with different leader are not equal', () {
        final s1 = SocietyState.initial();
        final s2 = SocietyState.initial().copyWith(
          currentLeaderId: 'candidate_1',
        );

        expect(s1, isNot(equals(s2)));
      });

      test('states with different electionCount are not equal', () {
        final s1 = SocietyState.initial();
        final s2 = SocietyState.initial().copyWith(electionCount: 1);

        expect(s1, isNot(equals(s2)));
      });
    });

    group('toJson / fromJson roundtrip', () {
      test('roundtrips initial state', () {
        final original = SocietyState.initial();
        final json = original.toJson();
        final restored = SocietyState.fromJson(json);

        expect(restored, equals(original));
        expect(restored.happiness, 50.0);
        expect(restored.mood, 0.3);
        expect(restored.electionCount, 0);
      });

      test('roundtrips state with all fields', () {
        final original = SocietyState(
          happiness: 75.5,
          mood: 0.65,
          currentLeaderId: 'candidate_1',
          electionCount: 3,
        );
        final json = original.toJson();
        final restored = SocietyState.fromJson(json);

        expect(restored, equals(original));
        expect(restored.happiness, 75.5);
        expect(restored.mood, 0.65);
        expect(restored.currentLeaderId, 'candidate_1');
        expect(restored.electionCount, 3);
      });

      test('roundtrips state with null leader', () {
        final original = SocietyState(
          happiness: 30.0,
          mood: 0.1,
          electionCount: 5,
        );
        final json = original.toJson();
        final restored = SocietyState.fromJson(json);

        expect(restored, equals(original));
        expect(restored.currentLeaderId, isNull);
      });
    });

    group('copyWith', () {
      test('updates happiness', () {
        final original = SocietyState.initial();
        final updated = original.copyWith(happiness: 80.0);

        expect(updated.happiness, 80.0);
        expect(updated.mood, original.mood);
        expect(updated.electionCount, original.electionCount);
      });

      test('updates mood', () {
        final original = SocietyState.initial();
        final updated = original.copyWith(mood: 0.75);

        expect(updated.mood, 0.75);
        expect(updated.happiness, original.happiness);
      });

      test('updates currentLeaderId', () {
        final original = SocietyState.initial();
        final updated = original.copyWith(currentLeaderId: 'candidate_3');

        expect(updated.currentLeaderId, 'candidate_3');
      });

      test('clears currentLeaderId with clearLeader flag', () {
        final original = SocietyState.initial().copyWith(
          currentLeaderId: 'candidate_1',
        );
        final updated = original.copyWith(clearLeader: true);

        expect(updated.currentLeaderId, isNull);
      });

      test('updates electionCount', () {
        final original = SocietyState.initial();
        final updated = original.copyWith(electionCount: 2);

        expect(updated.electionCount, 2);
      });

      test('returns same if no args', () {
        final original = SocietyState.initial();
        expect(original.copyWith(), equals(original));
      });
    });

    group('props', () {
      test('contains all fields', () {
        final state = SocietyState(
          happiness: 50.0,
          mood: 0.3,
          currentLeaderId: 'leader_1',
          electionCount: 5,
        );

        expect(state.props.length, 4);
        expect(state.props[0], 50.0);
        expect(state.props[1], 0.3);
        expect(state.props[2], 'leader_1');
        expect(state.props[3], 5);
      });
    });
  });
}
