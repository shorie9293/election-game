import 'package:hive/hive.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/game_state.dart';
// Job is defined inline in citizen.dart
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/repositories/game_repository.dart';

class HiveGameRepository implements GameRepository {
  static const _boxName = 'game_state';
  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<GameState> load() async {
    final data = _box?.get('state') as Map<String, dynamic>?;
    if (data == null) {
      // Return default state if nothing saved
      return GameState(
        citizen: Citizen(
          name: '',
          job: Job.unemployed,
          concerns: [],
          lifeParams: {},
        ),
        society: SocietyState.initial(),
        currentElection: null,
        pastElections: [],
      );
    }
    return GameState.fromJson(data);
  }

  @override
  Future<void> save(GameState state) async {
    await _box?.put('state', state.toJson());
  }
}
