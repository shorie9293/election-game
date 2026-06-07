import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/political_group.dart';

void main() {
  group('PoliticalGroup model', () {
    test('PoliticalGroupを生成できる', () {
      final group = PoliticalGroup(
        id: 'group_1',
        name: '発展の会',
        ideology: '経済成長で皆が豊かに',
        economicAxis: 0.8,
        welfareAxis: -0.2,
        supportedCandidateIds: ['cand_1', 'cand_2'],
      );

      expect(group.id, 'group_1');
      expect(group.name, '発展の会');
      expect(group.ideology, '経済成長で皆が豊かに');
      expect(group.economicAxis, 0.8);
      expect(group.welfareAxis, -0.2);
      expect(group.supportedCandidateIds.length, 2);
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final group = PoliticalGroup(
        id: 'group_2',
        name: '共生の会',
        ideology: '支え合う社会を',
        economicAxis: -0.3,
        welfareAxis: 0.9,
        supportedCandidateIds: ['cand_3'],
      );

      final json = group.toJson();
      final restored = PoliticalGroup.fromJson(json);

      expect(restored.name, '共生の会');
      expect(restored.economicAxis, -0.3);
      expect(restored.welfareAxis, 0.9);
    });

    test('samplesで5団体が生成される', () {
      final samples = PoliticalGroup.samples();
      expect(samples.length, 5);
      expect(samples[0].name, '発展の会');
      expect(samples[1].name, '共生の会');
      expect(samples[2].name, '守りの会');
      expect(samples[3].name, '緑の会');
      expect(samples[4].name, '改革の会');
    });

    test('copyWithで一部変更できる', () {
      final group = PoliticalGroup.samples().first;
      final updated = group.copyWith(name: '新しい会');
      expect(updated.name, '新しい会');
      expect(updated.id, group.id);
    });

    test('equatableで等価性が正しい', () {
      final a = PoliticalGroup.samples().first;
      final b = PoliticalGroup(
        id: 'group_development',
        name: '発展の会',
        ideology: '経済成長で皆が豊かに',
        economicAxis: 0.8,
        welfareAxis: -0.2,
        supportedCandidateIds: ['candidate_1', 'candidate_2'],
      );

      expect(a, equals(b));
    });
  });

  group('PoliticalGroups', () {
    test('fromCandidateIdで候補者の所属団体が取得できる', () {
      // samples() では 発展の会 が candidate_1, candidate_2 を支援
      final group = PoliticalGroups.fromCandidateId('candidate_1');
      expect(group, isNotNull);
      expect(group!.name, '発展の会');
    });

    test('fromCandidateIdで未所属の候補者はnullを返す', () {
      final group = PoliticalGroups.fromCandidateId('unknown');
      expect(group, isNull);
    });
  });
}
