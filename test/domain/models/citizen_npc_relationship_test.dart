import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/citizen_npc_relationship.dart';

void main() {
  group('CitizenNpcRelationship', () {
    test('factory.initial で初期値生成', () {
      final rel = CitizenNpcRelationship.initial('tanaka');
      expect(rel.npcId, 'tanaka');
      expect(rel.relationship, 0.0);
      expect(rel.interactionCount, 0);
    });

    test('カスタム値で生成できる', () {
      final rel = CitizenNpcRelationship(
        npcId: 'yamada',
        relationship: 0.3,
        interactionCount: 3,
      );
      expect(rel.npcId, 'yamada');
      expect(rel.relationship, 0.3);
      expect(rel.interactionCount, 3);
    });

    test('recordInteractionでカウントが増える', () {
      final rel = CitizenNpcRelationship.initial('suzuki');
      final updated = rel.recordInteraction(impact: 0.1);
      expect(updated.interactionCount, 1);

      final again = updated.recordInteraction(impact: 0.1);
      expect(again.interactionCount, 2);
    });

    test('recordInteraction 正の影響で関係値が上がる', () {
      final rel = CitizenNpcRelationship.initial('sato');
      final updated = rel.recordInteraction(impact: 0.5);
      expect(updated.relationship, closeTo(0.5, 0.001));
    });

    test('recordInteraction 負の影響で関係値が下がる', () {
      final rel = CitizenNpcRelationship.initial('ito');
      final updated = rel.recordInteraction(impact: -0.3);
      expect(updated.relationship, closeTo(-0.3, 0.001));
    });

    test('recordInteraction 関係値を-1.0〜1.0にクランプ', () {
      final rel = CitizenNpcRelationship(
        npcId: 'watanabe', relationship: 0.9, interactionCount: 0);
      final over = rel.recordInteraction(impact: 0.5);
      expect(over.relationship, 1.0);

      final rel2 = CitizenNpcRelationship(
        npcId: 'takahashi', relationship: -0.9, interactionCount: 0);
      final under = rel2.recordInteraction(impact: -0.5);
      expect(under.relationship, -1.0);
    });

    test('isFriendly > 0.5 で true', () {
      final rel = CitizenNpcRelationship(
        npcId: 'nakamura', relationship: 0.7, interactionCount: 0);
      expect(rel.isFriendly, true);
      expect(rel.isNeutral, false);
      expect(rel.isHostile, false);
    });

    test('isHostile < -0.5 で true', () {
      final rel = CitizenNpcRelationship(
        npcId: 'kobayashi', relationship: -0.7, interactionCount: 0);
      expect(rel.isHostile, true);
      expect(rel.isNeutral, false);
      expect(rel.isFriendly, false);
    });

    test('isNeutral -0.5〜0.5 で true', () {
      final rel = CitizenNpcRelationship(
        npcId: 'saito', relationship: 0.0, interactionCount: 0);
      expect(rel.isNeutral, true);
      expect(rel.isFriendly, false);
      expect(rel.isHostile, false);
    });

    test('relationshipTier が正しい段階を返す', () {
      expect(
        CitizenNpcRelationship(npcId: 'a', relationship: 0.9, interactionCount: 0)
            .relationshipTier,
        'friendly',
      );
      expect(
        CitizenNpcRelationship(npcId: 'b', relationship: 0.5, interactionCount: 0)
            .relationshipTier,
        'warm',
      );
      expect(
        CitizenNpcRelationship(npcId: 'c', relationship: 0.0, interactionCount: 0)
            .relationshipTier,
        'neutral',
      );
      expect(
        CitizenNpcRelationship(npcId: 'd', relationship: -0.5, interactionCount: 0)
            .relationshipTier,
        'cold',
      );
      expect(
        CitizenNpcRelationship(npcId: 'e', relationship: -0.9, interactionCount: 0)
            .relationshipTier,
        'hostile',
      );
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final rel = CitizenNpcRelationship(
        npcId: 'yamamoto',
        relationship: 0.7,
        interactionCount: 5,
      );
      final json = rel.toJson();
      final restored = CitizenNpcRelationship.fromJson(json);
      expect(restored.npcId, 'yamamoto');
      expect(restored.relationship, 0.7);
      expect(restored.interactionCount, 5);
    });

    test('copyWithで一部変更できる', () {
      final rel = CitizenNpcRelationship(
        npcId: 'matsumoto',
        relationship: 0.2,
        interactionCount: 2,
      );
      final updated = rel.copyWith(relationship: 0.8, interactionCount: 3);
      expect(updated.npcId, 'matsumoto');
      expect(updated.relationship, 0.8);
      expect(updated.interactionCount, 3);
    });

    test('equatableで等価性が正しい', () {
      final a = CitizenNpcRelationship(
        npcId: 'fujita', relationship: 0.3, interactionCount: 0);
      final b = CitizenNpcRelationship(
        npcId: 'fujita', relationship: 0.3, interactionCount: 0);
      final c = CitizenNpcRelationship(
        npcId: 'fujita', relationship: 0.4, interactionCount: 0);
      final d = CitizenNpcRelationship(
        npcId: 'ogawa', relationship: 0.3, interactionCount: 0);
      expect(a, b);
      expect(a, isNot(c));
      expect(a, isNot(d));
    });
  });
}
