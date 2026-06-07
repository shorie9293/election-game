import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';

void main() {
  group('Election model', () {
    test('Electionを生成できる', () {
      final candidates = Candidate.samples();
      final election = Election(
        id: 'election_1',
        title: '天照町 町長選挙',
        scale: ElectionScale.town,
        candidates: candidates,
        turnDeadline: 3,
        voteCounts: null,
        winnerId: null,
      );

      expect(election.id, 'election_1');
      expect(election.title, '天照町 町長選挙');
      expect(election.scale, ElectionScale.town);
      expect(election.candidates.length, 4);
      expect(election.turnDeadline, 3);
    });

    test('Election.sampleでサンプル選挙が生成される', () {
      final election = Election.sample();
      expect(election.title, '天照町 町長選挙');
      expect(election.scale, ElectionScale.town);
      expect(election.candidates.length, 4);
      expect(election.turnDeadline, 3);
    });

    test('copyWithで一部変更できる', () {
      final election = Election.sample();
      final updated = election.copyWith(winnerId: 'cand_1');
      expect(updated.winnerId, 'cand_1');
      expect(updated.id, election.id);
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final election = Election.sample();
      final json = election.toJson();
      final restored = Election.fromJson(json);

      expect(restored.title, '天照町 町長選挙');
      expect(restored.candidates.length, 4);
    });

    test('completedフラグが正しく判定される', () {
      final ongoing = Election.sample();
      expect(ongoing.completed, false);

      final completed = Election.sample().copyWith(winnerId: 'cand_1', voteCounts: {'cand_1': 60, 'cand_2': 40});
      expect(completed.completed, true);
    });
  });
}
