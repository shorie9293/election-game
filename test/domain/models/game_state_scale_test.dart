import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';

void main() {
  group('GameState scale progression', () {
    GameState createInitialState() {
      return GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト市民'),
        society: SocietyState.initial(),
        remainingTurns: 0,
      );
    }

    GameState simulateElectionComplete(GameState state) {
      final newElectionCount = state.electionCount + 1;
      final currentScale = state.scale;
      final shouldAdvanceScale =
          newElectionCount % currentScale.electionsNeeded == 0;
      final nextScale = currentScale.advanceTo;

      return state.copyWith(
        electionCount: newElectionCount,
        scale: shouldAdvanceScale && nextScale != null
            ? nextScale
            : currentScale,
      );
    }

    test('初期状態は村(Village)', () {
      final state = createInitialState();
      expect(state.scale, ElectionScale.village);
      expect(state.electionCount, 0);
    });

    test('1回目の選挙後も村のまま', () {
      final state = simulateElectionComplete(createInitialState());
      expect(state.scale, ElectionScale.village);
      expect(state.electionCount, 1);
    });

    test('2回目の選挙後も村のまま', () {
      var state = createInitialState();
      state = simulateElectionComplete(state);
      state = simulateElectionComplete(state);
      expect(state.scale, ElectionScale.village);
      expect(state.electionCount, 2);
    });

    test('3回目の選挙後に村→町へ進化（village→town）', () {
      var state = createInitialState();
      for (int i = 0; i < 3; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.town);
      expect(state.electionCount, 3);
    });

    test('4回目の選挙後も町のまま', () {
      var state = createInitialState();
      for (int i = 0; i < 4; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.town);
      expect(state.electionCount, 4);
    });

    test('6回目の選挙後に町→市へ進化（town→city）', () {
      var state = createInitialState();
      for (int i = 0; i < 6; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.city);
      expect(state.electionCount, 6);
    });

    test('7回目の選挙後も市のまま', () {
      var state = createInitialState();
      for (int i = 0; i < 7; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.city);
      expect(state.electionCount, 7);
    });

    test('9回目の選挙後も市のまま（cityが最終）', () {
      var state = createInitialState();
      for (int i = 0; i < 9; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.city);
      expect(state.electionCount, 9);
    });

    test('村→町→市の全段階進行', () {
      var state = createInitialState();

      // 村 (0→3)
      expect(state.scale, ElectionScale.village);
      for (int i = 0; i < 3; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.town);

      // 町 (3→6)
      for (int i = 0; i < 3; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.city);

      // 市 (6→9)
      for (int i = 0; i < 3; i++) {
        state = simulateElectionComplete(state);
      }
      expect(state.scale, ElectionScale.city);
      expect(state.electionCount, 9);
    });
  });
}
