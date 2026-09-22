import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/candidate_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EffectSummary.display', () {
    test('正の値は + を付けて表示する', () {
      expect(
        const EffectSummary(key: 'lifeCost', label: '生活費', value: 10).display,
        '+10',
      );
    });

    test('負の値はそのまま表示する', () {
      expect(
        const EffectSummary(key: 'lifeCost', label: '生活費', value: -5).display,
        '-5',
      );
    });

    test('ゼロは ±0 と表示する', () {
      expect(
        const EffectSummary(key: 'lifeCost', label: '生活費', value: 0).display,
        '±0',
      );
    });

    test('+1 と -1 の境界も正しく表示する', () {
      expect(
        const EffectSummary(key: 'k', label: 'l', value: 1).display,
        '+1',
      );
      expect(
        const EffectSummary(key: 'k', label: 'l', value: -1).display,
        '-1',
      );
    });

    test('同値の EffectSummary は等価である（Equatable）', () {
      expect(
        const EffectSummary(key: 'lifeCost', label: '生活費', value: 3),
        equals(const EffectSummary(key: 'lifeCost', label: '生活費', value: 3)),
      );
    });
  });

  group('CandidateProfile', () {
    test('policyCount は公約の件数を返す', () {
      final c = Candidate.samples().first;
      final p = CandidateProfile(
        candidate: c,
        effects: const [],
        dominantCategory: '経済',
      );
      expect(p.policyCount, c.policies.length);
    });

    test('totalEffectScore は totalEffects の値の合計を返す', () {
      final c = Candidate.samples().first;
      var expected = 0;
      for (final v in c.totalEffects.values) {
        expected += v;
      }
      final p = CandidateProfile(
        candidate: c,
        effects: const [],
        dominantCategory: '',
      );
      expect(p.totalEffectScore, expected);
    });

    test('totalEffectScore は負にもなり得る', () {
      final c = Candidate(
        id: 'neg',
        name: '負候補',
        portraitKey: 'p',
        faction: '負の会',
        personality: '削減',
        policies: [
          const Policy(
            title: '大型削減',
            description: '全て削る',
            category: '経済',
            effects: {'lifeCost': -10, 'employment': -3},
          ),
        ],
      );
      final p = CandidateProfile(
        candidate: c,
        effects: const [],
        dominantCategory: '経済',
      );
      expect(p.totalEffectScore, -13);
    });

    test('hasPolicies は公約 0 件で false・1 件以上で true', () {
      final none = CandidateProfile(
        candidate: Candidate(
          id: 'none',
          name: '無公約',
          portraitKey: 'p',
          faction: '無',
          personality: '自由',
          policies: const [],
        ),
        effects: const [],
        dominantCategory: '',
      );
      final some = CandidateProfile(
        candidate: Candidate.samples().first,
        effects: const [],
        dominantCategory: '経済',
      );
      expect(none.hasPolicies, isFalse);
      expect(some.hasPolicies, isTrue);
    });

    test('同内容の CandidateProfile は等価である（Equatable）', () {
      final c = Candidate.samples().first;
      final a = CandidateProfile(
        candidate: c,
        effects: const [],
        dominantCategory: '経済',
      );
      final b = CandidateProfile(
        candidate: c,
        effects: const [],
        dominantCategory: '経済',
      );
      expect(a, equals(b));
    });
  });
}
