import 'package:equatable/equatable.dart';
import 'citizen.dart';
import 'election.dart';
import 'society_state.dart';

class GameState extends Equatable {
  final Citizen citizen;
  final SocietyState society;
  final Election? currentElection;
  final List<Election> pastElections;

  const GameState({
    required this.citizen,
    required this.society,
    this.currentElection,
    this.pastElections = const [],
  });

  GameState copyWith({
    Citizen? citizen,
    SocietyState? society,
    Election? currentElection,
    List<Election>? pastElections,
    bool clearCurrentElection = false,
  }) {
    return GameState(
      citizen: citizen ?? this.citizen,
      society: society ?? this.society,
      currentElection: clearCurrentElection
          ? null
          : (currentElection ?? this.currentElection),
      pastElections: pastElections ?? this.pastElections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'citizen': citizen.toJson(),
      'society': society.toJson(),
      'currentElection': currentElection?.toJson(),
      'pastElections': pastElections.map((e) => e.toJson()).toList(),
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
    );
  }

  @override
  List<Object?> get props =>
      [citizen, society, currentElection, pastElections];
}
