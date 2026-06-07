import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:election_game/core/error/error_boundary.dart';
import 'package:election_game/features/citizen/presentation/citizen_create_screen.dart';
import 'package:election_game/features/election/presentation/election_announcement_screen.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/features/vote/presentation/vote_screen.dart';
import 'package:election_game/features/newspaper/presentation/result_screen.dart';
import 'package:election_game/features/shared/viewmodels/game_notifier.dart';

enum _GamePhase { citizenCreate, home, electionAnnouncement, voting, result }

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  _GamePhase _phase = _GamePhase.citizenCreate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(gameNotifierProvider);
      if (state.citizen.name.isNotEmpty) {
        setState(() => _phase = _GamePhase.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);

    return ErrorBoundaryWidget(
      child: switch (_phase) {
        _GamePhase.citizenCreate => CitizenCreateScreen(
            onCreated: (citizen) {
              ref.read(gameNotifierProvider.notifier)
                ..createCitizen(citizen.name, citizen.job)
                ..loadSave();
              setState(() => _phase = _GamePhase.home);
            },
          ),
        _GamePhase.home => HomeScreen(
            citizen: gameState.citizen,
            society: gameState.society,
            onGoToElection: () {
              ref
                  .read(gameNotifierProvider.notifier)
                  .startElection();
              setState(() => _phase = _GamePhase.electionAnnouncement);
            },
          ),
        _GamePhase.electionAnnouncement =>
          ElectionAnnouncementScreen(
            election: gameState.currentElection!,
            society: gameState.society,
            onProceed: () =>
                setState(() => _phase = _GamePhase.voting),
          ),
        _GamePhase.voting => VoteScreen(
            candidates: gameState.currentElection!.candidates,
            onVote: (candidateId) {
              final notifier =
                  ref.read(gameNotifierProvider.notifier);
              final oldSociety = gameState.society;
              final oldLifeParams =
                  Map<String, int>.from(gameState.citizen.lifeParams);
              notifier.castVote(candidateId);
              final newState = ref.read(gameNotifierProvider);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ErrorBoundaryWidget(
                    child: ResultScreen(
                      election: newState.currentElection!,
                      previousSociety: oldSociety,
                      newSociety: newState.society,
                      oldLifeParams: oldLifeParams,
                      newLifeParams: newState.citizen.lifeParams,
                      onContinue: () {
                        ref
                            .read(gameNotifierProvider.notifier)
                            .advanceAfterResult();
                        setState(() => _phase = _GamePhase.home);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        _GamePhase.result => const SizedBox.shrink(),
      },
    );
  }
}
