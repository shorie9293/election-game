import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate.dart';

void main() {
  group('Policy model', () {
    test('Policyを生成できる', () {
      final policy = Policy(
        title: '減税',
        description: '所得税を10%引き下げる',
        category: '経済',
        effects: {'lifeCost': -10, 'employment': 5},
      );

      expect(policy.title, '減税');
      expect(policy.description, '所得税を10%引き下げる');
      expect(policy.category, '経済');
      expect(policy.effects['lifeCost'], -10);
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final policy = Policy(
        title: '医療拡充',
        description: '医療アクセスを改善',
        category: '医療',
        effects: {'healthcare': 10, 'lifeCost': 5},
      );

      final json = policy.toJson();
      final restored = Policy.fromJson(json);

      expect(restored.title, '医療拡充');
      expect(restored.category, '医療');
      expect(restored.effects['healthcare'], 10);
    });

    test('copyWithで一部変更できる', () {
      final policy = Policy(
        title: '原案',
        description: '説明',
        category: '経済',
        effects: {'lifeCost': 5},
      );

      final updated = policy.copyWith(title: '変更後');
      expect(updated.title, '変更後');
      expect(updated.description, '説明');
    });
  });

  group('Candidate model', () {
    test('Candidateを生成できる', () {
      final candidate = Candidate(
        id: 'cand_1',
        name: '山田太郎',
        portraitKey: 'portrait_yamada',
        faction: '発展の会',
        personality: '穏健な実務家',
        policies: [
          Policy(
            title: '減税',
            description: '所得税を下げる',
            category: '経済',
            effects: {'lifeCost': -10},
          ),
        ],
      );

      expect(candidate.id, 'cand_1');
      expect(candidate.name, '山田太郎');
      expect(candidate.portraitKey, 'portrait_yamada');
      expect(candidate.faction, '発展の会');
      expect(candidate.policies.length, 1);
    });

    test('totalEffectsで全公約の効果が合計される', () {
      final candidate = Candidate(
        id: 'cand_1',
        name: 'テスト候補',
        portraitKey: 'portrait_test',
        faction: 'テスト',
        personality: 'テスト',
        policies: [
          Policy(
            title: '公約1',
            description: '説明1',
            category: '経済',
            effects: {'lifeCost': -10, 'employment': 5},
          ),
          Policy(
            title: '公約2',
            description: '説明2',
            category: '環境',
            effects: {'environment': 8, 'lifeCost': 3},
          ),
        ],
      );

      final effects = candidate.totalEffects;
      expect(effects['lifeCost'], -7); // -10 + 3
      expect(effects['employment'], 5);
      expect(effects['environment'], 8);
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final candidate = Candidate(
        id: 'cand_1',
        name: 'テスト',
        portraitKey: 'portrait_test',
        faction: '発展の会',
        personality: '実務家',
        policies: [
          Policy(
            title: '減税',
            description: '説明',
            category: '経済',
            effects: {'lifeCost': -10},
          ),
        ],
      );

      final json = candidate.toJson();
      final restored = Candidate.fromJson(json);

      expect(restored.id, 'cand_1');
      expect(restored.name, 'テスト');
      expect(restored.faction, '発展の会');
      expect(restored.policies.length, 1);
    });

    test('samplesで4人の候補者が生成される', () {
      final samples = Candidate.samples();
      expect(samples.length, 4);
      expect(samples[0].name, '山田太郎');
      expect(samples[1].name, '佐藤花子');
      expect(samples[2].name, '鈴木一郎');
      expect(samples[3].name, '田中美咲');
    });

    test('copyWithで一部変更できる', () {
      final candidate = Candidate.samples().first;
      final updated = candidate.copyWith(name: '新しい名前');
      expect(updated.name, '新しい名前');
      expect(updated.id, candidate.id);
    });
  });
}
