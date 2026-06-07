import 'package:equatable/equatable.dart';
import 'citizen.dart';
import 'citizen_npc_relationship.dart';
import 'concern_evolution.dart';
import 'election.dart';
import 'election_scale.dart';
import 'society_state.dart';

/// ゲーム全体の状態を管理
/// 段階進行（村→町→市）のスケール管理を含む
class GameState extends Equatable {
  final Citizen citizen;
  final SocietyState society;
  final Election? currentElection;
  final List<Election> pastElections;
  final int remainingTurns;
  final int electionCount;
  final ElectionScale scale;
  final List<ConcernEvolution> concernEvolutions;
  final Map<String, CitizenNpcRelationship> npcRelationships;

  const GameState({
    required this.citizen,
    required this.society,
    this.currentElection,
    this.pastElections = const [],
    this.remainingTurns = 10,
    this.electionCount = 0,
    this.scale = ElectionScale.village,
    this.concernEvolutions = const [],
    this.npcRelationships = const {},
  });

  GameState copyWith({
    Citizen? citizen,
    SocietyState? society,
    Election? currentElection,
    List<Election>? pastElections,
    int? remainingTurns,
    int? electionCount,
    ElectionScale? scale,
    List<ConcernEvolution>? concernEvolutions,
    Map<String, CitizenNpcRelationship>? npcRelationships,
    bool clearCurrentElection = false,
  }) {
    return GameState(
      citizen: citizen ?? this.citizen,
      society: society ?? this.society,
      currentElection: clearCurrentElection
          ? null
          : (currentElection ?? this.currentElection),
      pastElections: pastElections ?? this.pastElections,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      electionCount: electionCount ?? this.electionCount,
      scale: scale ?? this.scale,
      concernEvolutions: concernEvolutions ?? this.concernEvolutions,
      npcRelationships: npcRelationships ?? this.npcRelationships,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'citizen': citizen.toJson(),
      'society': society.toJson(),
      'currentElection': currentElection?.toJson(),
      'pastElections': pastElections.map((e) => e.toJson()).toList(),
      'remainingTurns': remainingTurns,
      'electionCount': electionCount,
      'scale': scale.toJson(),
      'concernEvolutions':
          concernEvolutions.map((e) => e.toJson()).toList(),
      'npcRelationships':
          npcRelationships.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      citizen: Citizen.fromJson(json['citizen'] as Map<String, dynamic>),
      society:
          SocietyState.fromJson(json['society'] as Map<String, dynamic>),
      currentElection: json['currentElection'] != null
          ? Election.fromJson(json['currentElection'] as Map<String, dynamic>)
          : null,
      pastElections: (json['pastElections'] as List)
          .map((e) => Election.fromJson(e as Map<String, dynamic>))
          .toList(),
      remainingTurns: json['remainingTurns'] as int? ?? 10,
      electionCount: json['electionCount'] as int? ?? 0,
      scale: json['scale'] != null
          ? ElectionScale.fromJson(json['scale'] as Map<String, dynamic>)
          : ElectionScale.village,
      concernEvolutions: json['concernEvolutions'] != null
          ? (json['concernEvolutions'] as List)
              .map((e) =>
                  ConcernEvolution.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      npcRelationships: json['npcRelationships'] != null
          ? (json['npcRelationships'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                  k,
                  CitizenNpcRelationship.fromJson(
                      v as Map<String, dynamic>)),
            )
          : {},
    );
  }

  @override
  List<Object?> get props => [
        citizen,
        society,
        currentElection,
        pastElections,
        remainingTurns,
        electionCount,
        scale,
        concernEvolutions,
        npcRelationships,
      ];
}
