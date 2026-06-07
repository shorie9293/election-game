import 'package:election_game/domain/models/game_state.dart';

abstract class GameRepository {
  Future<GameState> load();
  Future<void> save(GameState state);
}
