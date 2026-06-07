import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/repositories/game_repository.dart';
import 'package:election_game/domain/services/election_service.dart';

final gameNotifierProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) {
  throw UnimplementedError('Repository must be injected');
});

class GameNotifier extends StateNotifier<GameState> {
  final GameRepository _repo;

  GameNotifier(this._repo, GameState initialState) : super(initialState);

  /// Creates an empty default state for initialization
  static GameState emptyState() {
    return GameState(
      citizen: Citizen.initial(Job.unemployed),
      society: SocietyState.initial(),
    );
  }

  Future<void> initialize() async {
    final saved = await _repo.load();
    state = saved;
  }

  void createCitizen(String name, Job job) {
    final citizen = Citizen.initial(job).copyWith(name: name);
    state = state.copyWith(citizen: citizen);
    _repo.save(state);
  }

  void startElection() {
    final candidates = ElectionService.determineCandidates(state.society);
    final election = Election.sampleVillage().copyWith(candidates: candidates);
    state = state.copyWith(currentElection: election);
    _repo.save(state);
  }

  void castVote(String candidateId) {
    if (state.currentElection == null) return;

    // Simulate the election result
    final result = ElectionService.computeElectionResult(state.currentElection!);

    // Apply policies to citizen life
    final newLifeParams = ElectionService.applyElectionToLife(
      state.citizen.lifeParams,
      result,
    );

    // Compute mood change
    final newMood = ElectionService.computeMoodChange(state.society, result);

    final newSociety = state.society.copyWith(
      happiness: state.society.happiness,
      mood: newMood,
      currentLeaderId: result.winnerId,
      electionCount: state.society.electionCount + 1,
    );

    final newCitizen = state.citizen.copyWith(lifeParams: newLifeParams);

    state = state.copyWith(
      citizen: newCitizen,
      society: newSociety,
      currentElection: result,
      pastElections: [...state.pastElections, result],
    );
    _repo.save(state);
  }

  void advanceAfterResult() {
    state = state.copyWith(
      clearCurrentElection: true,
    );
    _repo.save(state);
  }

  void loadSave() async {
    final saved = await _repo.load();
    state = saved;
  }
}
