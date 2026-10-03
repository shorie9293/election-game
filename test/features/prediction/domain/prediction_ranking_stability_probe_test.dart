import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/prediction/domain/prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 親探針: ranking の「同数は宣言順を保つ安定ソート」不変条件を、
/// List.sort の非安定パス（要素数 > 32）を含む大規模タイで撃つ。
void main() {
  group('PredictionService.ranking 安定性の親探針', () {
    test('40件すべて同得票でも宣言順を厳密に保つ（非安定ソートの混入検出）', () {
      final candidates = List<Candidate>.generate(
        40,
        (i) => Candidate(
          id: 'c$i',
          name: '候補$i',
          portraitKey: 'p$i',
          faction: 'f',
          personality: 'personality',
          policies: const [],
        ),
      );
      final election = Election(
        id: 'e_big_tie',
        title: '大規模タイ選挙',
        scale: ElectionScale.town,
        candidates: candidates,
        voteCounts: {for (final c in candidates) c.id: 1},
        winnerId: 'c0',
      );

      expect(
        PredictionService.ranking(election),
        candidates.map((c) => c.id).toList(),
      );
    });

    test('部分的なタイでも得票降順→宣言順の辞書式順序になる', () {
      // 宣言順: a(3), b(2), c(2), d(1), e(2)  -> 得票降順: a, b, c, e, d
      final candidates = [
        _c('a'),
        _c('b'),
        _c('c'),
        _c('d'),
        _c('e'),
      ];
      final election = Election(
        id: 'e_partial',
        title: 'タイ混在',
        scale: ElectionScale.town,
        candidates: candidates,
        voteCounts: {'a': 3, 'b': 2, 'c': 2, 'd': 1, 'e': 2},
        winnerId: 'a',
      );

      expect(
        PredictionService.ranking(election),
        ['a', 'b', 'c', 'e', 'd'],
      );
    });
  });
}

Candidate _c(String id) => Candidate(
      id: id,
      name: id,
      portraitKey: id,
      faction: 'f',
      personality: 'personality',
      policies: const [],
    );
