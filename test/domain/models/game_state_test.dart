import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_npc_relationship.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';

void main() {
  group('GameState model', () {
    test('GameStateを生成できる', () {
      final state = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: '市民A'),
        society: SocietyState.initial(),
      );

      expect(state.citizen.name, '市民A');
      expect(state.society.happiness, 50.0);
      expect(state.remainingTurns, 10);
      expect(state.electionCount, 0);
      expect(state.scale, ElectionScale.village);
    });

    test('copyWithで一部変更できる', () {
      final state = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: '市民A'),
        society: SocietyState.initial(),
      );

      final updated = state.copyWith(remainingTurns: 5, electionCount: 2);
      expect(updated.remainingTurns, 5);
      expect(updated.electionCount, 2);
      expect(updated.citizen.name, '市民A');
      expect(updated.scale, ElectionScale.village);
    });

    test('scaleを変更できる', () {
      final state = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: '市民A'),
        society: SocietyState.initial(),
      );

      final updated = state.copyWith(scale: ElectionScale.town);
      expect(updated.scale, ElectionScale.town);
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final state = GameState(
        citizen: Citizen.initial(Job.doctor).copyWith(name: '医者'),
        society: SocietyState.initial().copyWith(electionCount: 3),
        currentElection: Election.sample(),
        electionCount: 5,
        scale: ElectionScale.city,
      );

      final json = state.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.citizen.name, '医者');
      expect(restored.society.electionCount, 3);
      expect(restored.currentElection, isNotNull);
      expect(restored.currentElection!.title, '天照町 町長選挙');
      expect(restored.electionCount, 5);
      expect(restored.scale, ElectionScale.city);
    });

    test('npcRelationships を保存できる', () {
      final state = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: 'A'),
        society: SocietyState.initial(),
        npcRelationships: {
          'npc_goro': const CitizenNpcRelationship(
            npcId: 'npc_goro',
            relationship: 0.5,
            interactionCount: 3,
          ),
        },
      );

      expect(state.npcRelationships['npc_goro']!.relationship, 0.5);
      expect(state.npcRelationships['npc_goro']!.interactionCount, 3);
    });

    test('copyWith で npcRelationships が保持される', () {
      final state = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: 'A'),
        society: SocietyState.initial(),
        npcRelationships: {
          'npc_sakura': const CitizenNpcRelationship(
            npcId: 'npc_sakura', relationship: 0.3, interactionCount: 1,
          ),
        },
      );

      final updated = state.copyWith(remainingTurns: 5);
      expect(updated.npcRelationships['npc_sakura']!.relationship, 0.3);

      // copyWith で npcRelationships も上書き可能
      final overridden = state.copyWith(
        npcRelationships: {
          'npc_tetsuya': const CitizenNpcRelationship(
            npcId: 'npc_tetsuya', relationship: -0.2, interactionCount: 1,
          ),
        },
      );
      expect(overridden.npcRelationships.length, 1);
      expect(overridden.npcRelationships['npc_tetsuya']!.relationship, -0.2);
      expect(overridden.npcRelationships['npc_sakura'], isNull);
    });

    test('toJson/fromJson で npcRelationships が保存される', () {
      final state = GameState(
        citizen: Citizen.initial(Job.doctor).copyWith(name: '医者'),
        society: SocietyState.initial(),
        npcRelationships: {
          'npc_goro': const CitizenNpcRelationship(
            npcId: 'npc_goro', relationship: 0.8, interactionCount: 5,
          ),
          'npc_sakura': const CitizenNpcRelationship(
            npcId: 'npc_sakura', relationship: -0.3, interactionCount: 2,
          ),
        },
      );

      final json = state.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.npcRelationships.length, 2);
      expect(restored.npcRelationships['npc_goro']!.relationship, 0.8);
      expect(restored.npcRelationships['npc_goro']!.interactionCount, 5);
      expect(restored.npcRelationships['npc_sakura']!.relationship, -0.3);
      expect(restored.npcRelationships['npc_sakura']!.interactionCount, 2);
    });

    test('equatableで等価性が正しい', () {
      final a = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: 'A'),
        society: SocietyState.initial(),
      );
      final b = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: 'A'),
        society: SocietyState.initial(),
      );
      expect(a, equals(b));
    });

    test('electionCountとscaleの違いで等価性が変わる', () {
      final a = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: 'A'),
        society: SocietyState.initial(),
        electionCount: 1,
      );
      final b = GameState(
        citizen: Citizen.initial(Job.farmer).copyWith(name: 'A'),
        society: SocietyState.initial(),
        electionCount: 2,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
