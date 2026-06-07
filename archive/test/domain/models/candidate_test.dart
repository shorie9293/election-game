import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate.dart';

void main() {
  group('Policy', () {
    test('creates a Policy with correct values', () {
      final policy = Policy(
        title: '減税',
        description: '所得税を引き下げる',
        category: '経済',
        effects: {'lifeCost': -10, 'healthcare': -5},
      );

      expect(policy.title, '減税');
      expect(policy.description, '所得税を引き下げる');
      expect(policy.category, '経済');
      expect(policy.effects, {'lifeCost': -10, 'healthcare': -5});
    });

    group('Equatable', () {
      test('two identical policies are equal', () {
        final p1 = Policy(
          title: '減税',
          description: '所得税を引き下げる',
          category: '経済',
          effects: {'lifeCost': -10},
        );
        final p2 = Policy(
          title: '減税',
          description: '所得税を引き下げる',
          category: '経済',
          effects: {'lifeCost': -10},
        );

        expect(p1, equals(p2));
      });

      test('policies with different titles are not equal', () {
        final p1 = Policy(
          title: '減税',
          description: '所得税を引き下げる',
          category: '経済',
          effects: {'lifeCost': -10},
        );
        final p2 = Policy(
          title: '増税',
          description: '所得税を引き下げる',
          category: '経済',
          effects: {'lifeCost': -10},
        );

        expect(p1, isNot(equals(p2)));
      });
    });

    group('toJson / fromJson roundtrip', () {
      test('roundtrips a policy', () {
        final original = Policy(
          title: '医療拡充',
          description: '医療アクセスを改善',
          category: '医療',
          effects: {'healthcare': 10, 'lifeCost': 5},
        );
        final json = original.toJson();
        final restored = Policy.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('copyWith', () {
      test('updates title', () {
        final original = Policy(
          title: '減税',
          description: '所得税を引き下げる',
          category: '経済',
          effects: {'lifeCost': -10},
        );
        final updated = original.copyWith(title: '増税');

        expect(updated.title, '増税');
        expect(updated.description, original.description);
      });

      test('returns same if no args', () {
        final original = Policy(
          title: '減税',
          description: '所得税を引き下げる',
          category: '経済',
          effects: {'lifeCost': -10},
        );
        expect(original.copyWith(), equals(original));
      });
    });
  });

  group('Candidate', () {
    group('Candidate.samples()', () {
      test('returns 4 candidates', () {
        final candidates = Candidate.samples();
        expect(candidates.length, 4);
      });

      test('first candidate is 山田太郎 with correct data', () {
        final candidates = Candidate.samples();
        final c1 = candidates[0];

        expect(c1.id, 'candidate_1');
        expect(c1.name, '山田太郎');
        expect(c1.faction, '発展の会');
        expect(c1.personality, '経済成長で皆が豊かに');
        expect(c1.policies.length, 2);
        expect(c1.policies[0].title, '大規模開発');
        expect(c1.policies[1].title, '減税');
      });

      test('second candidate is 佐藤花子 with correct data', () {
        final candidates = Candidate.samples();
        final c2 = candidates[1];

        expect(c2.id, 'candidate_2');
        expect(c2.name, '佐藤花子');
        expect(c2.faction, '共生の会');
        expect(c2.personality, '支え合う社会を');
        expect(c2.policies[0].title, '医療拡充');
        expect(c2.policies[1].title, '教育無償化');
      });

      test('third candidate is 鈴木一郎 with correct data', () {
        final candidates = Candidate.samples();
        final c3 = candidates[2];

        expect(c3.id, 'candidate_3');
        expect(c3.name, '鈴木一郎');
        expect(c3.faction, '守りの会');
        expect(c3.personality, '伝統と安定');
        expect(c3.policies[0].title, '治安強化');
        expect(c3.policies[1].title, '地場産業保護');
      });

      test('fourth candidate is 田中美咲 with correct data', () {
        final candidates = Candidate.samples();
        final c4 = candidates[3];

        expect(c4.id, 'candidate_4');
        expect(c4.name, '田中美咲');
        expect(c4.faction, '改革の会');
        expect(c4.personality, '若者の声を');
        expect(c4.policies[0].title, '起業支援');
        expect(c4.policies[1].title, '環境投資');
      });

      test('all candidates have unique IDs', () {
        final candidates = Candidate.samples();
        final ids = candidates.map((c) => c.id).toSet();
        expect(ids.length, 4);
      });
    });

    group('Equatable', () {
      test('two identical candidates are equal', () {
        final candidates = Candidate.samples();
        final c1 = candidates[0];
        final c2 = candidates[0];

        expect(c1, equals(c2));
      });

      test('candidates with different ids are not equal', () {
        final candidates = Candidate.samples();
        expect(candidates[0], isNot(equals(candidates[1])));
      });
    });

    group('toJson / fromJson roundtrip', () {
      test('roundtrips all sample candidates', () {
        final candidates = Candidate.samples();
        for (final original in candidates) {
          final json = original.toJson();
          final restored = Candidate.fromJson(json);

          expect(restored, equals(original));
          expect(restored.id, original.id);
          expect(restored.name, original.name);
          expect(restored.policies.length, original.policies.length);
          expect(restored.policies[0].title, original.policies[0].title);
        }
      });

      test('roundtrips a candidate with policies', () {
        final original = Candidate(
          id: 'test_1',
          name: 'テスト候補',
          faction: 'テストの会',
          personality: 'テスト候補です',
          policies: [
            Policy(
              title: 'テスト政策',
              description: 'テストの説明',
              category: 'テスト',
              effects: {'test': 1},
            ),
          ],
        );
        final json = original.toJson();
        final restored = Candidate.fromJson(json);

        expect(restored, equals(original));
        expect(restored.policies[0].title, 'テスト政策');
      });
    });

    group('copyWith', () {
      test('updates name', () {
        final original = Candidate.samples()[0];
        final updated = original.copyWith(name: '新しい名前');

        expect(updated.name, '新しい名前');
        expect(updated.id, original.id);
        expect(updated.faction, original.faction);
      });

      test('updates faction', () {
        final original = Candidate.samples()[0];
        final updated = original.copyWith(faction: '新しい会');

        expect(updated.faction, '新しい会');
        expect(updated.id, original.id);
      });

      test('returns same if no args', () {
        final original = Candidate.samples()[0];
        expect(original.copyWith(), equals(original));
      });
    });

    group('props', () {
      test('candidate props contains all fields', () {
        final candidate = Candidate.samples()[0];
        expect(candidate.props.length, 5);
        expect(candidate.props[0], 'candidate_1');
        expect(candidate.props[1], '山田太郎');
        expect(candidate.props[2], '発展の会');
        expect(candidate.props[3], '経済成長で皆が豊かに');
        expect(candidate.props[4], isA<List<Policy>>());
      });
    });
  });
}
