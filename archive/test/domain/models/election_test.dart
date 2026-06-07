import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/candidate.dart';

void main() {
  group('Election', () {
    group('Election.sampleVillage()', () {
      test('creates an election with correct default values', () {
        final election = Election.sampleVillage();

        expect(election.id, 'election_1');
        expect(election.title, '天照町 町長選挙');
        expect(election.scale, 'village');
        expect(election.candidates.length, 4);
        expect(election.candidates[0].name, '山田太郎');
        expect(election.candidates[1].name, '佐藤花子');
        expect(election.candidates[2].name, '鈴木一郎');
        expect(election.candidates[3].name, '田中美咲');
      });

      test('voteCounts defaults to null', () {
        final election = Election.sampleVillage();
        expect(election.voteCounts, isNull);
      });

      test('winnerId defaults to null', () {
        final election = Election.sampleVillage();
        expect(election.winnerId, isNull);
      });
    });

    group('Equatable', () {
      test('two identical elections are equal', () {
        final e1 = Election.sampleVillage();
        final e2 = Election.sampleVillage();

        expect(e1, equals(e2));
      });

      test('elections with different ids are not equal', () {
        final e1 = Election.sampleVillage();
        final e2 = Election(
          id: 'election_2',
          title: '天照町 町長選挙',
          scale: 'village',
          candidates: Candidate.samples(),
        );

        expect(e1, isNot(equals(e2)));
      });

      test('elections with voteCounts are not equal to those without', () {
        final e1 = Election.sampleVillage();
        final e2 = Election(
          id: 'election_1',
          title: '天照町 町長選挙',
          scale: 'village',
          candidates: Candidate.samples(),
          voteCounts: {'candidate_1': 100},
        );

        expect(e1, isNot(equals(e2)));
      });

      test('elections with different winnerId are not equal', () {
        final e1 = Election(
          id: 'election_1',
          title: '天照町 町長選挙',
          scale: 'village',
          candidates: Candidate.samples(),
          winnerId: 'candidate_1',
        );
        final e2 = Election(
          id: 'election_1',
          title: '天照町 町長選挙',
          scale: 'village',
          candidates: Candidate.samples(),
          winnerId: 'candidate_2',
        );

        expect(e1, isNot(equals(e2)));
      });
    });

    group('toJson / fromJson roundtrip', () {
      test('roundtrips a sample village election', () {
        final original = Election.sampleVillage();
        final json = original.toJson();
        final restored = Election.fromJson(json);

        expect(restored, equals(original));
        expect(restored.id, 'election_1');
        expect(restored.title, '天照町 町長選挙');
        expect(restored.candidates.length, 4);
      });

      test('roundtrips an election with voteCounts and winnerId', () {
        final original = Election(
          id: 'election_2',
          title: 'テスト選挙',
          scale: 'city',
          candidates: Candidate.samples(),
          voteCounts: {'candidate_1': 150, 'candidate_2': 100},
          winnerId: 'candidate_1',
        );
        final json = original.toJson();
        final restored = Election.fromJson(json);

        expect(restored, equals(original));
        expect(restored.voteCounts, {'candidate_1': 150, 'candidate_2': 100});
        expect(restored.winnerId, 'candidate_1');
      });

      test('roundtrips an election with null winnerId', () {
        final original = Election(
          id: 'election_3',
          title: '結果未確定',
          scale: 'village',
          candidates: Candidate.samples(),
          voteCounts: {'candidate_1': 50, 'candidate_2': 50},
        );
        final json = original.toJson();
        final restored = Election.fromJson(json);

        expect(restored, equals(original));
        expect(restored.winnerId, isNull);
      });

      test('roundtrips an election with null voteCounts', () {
        final original = Election(
          id: 'election_4',
          title: '投票前',
          scale: 'village',
          candidates: Candidate.samples(),
        );
        final json = original.toJson();
        final restored = Election.fromJson(json);

        expect(restored, equals(original));
        expect(restored.voteCounts, isNull);
      });
    });

    group('copyWith', () {
      test('updates title', () {
        final original = Election.sampleVillage();
        final updated = original.copyWith(title: '新しい選挙');

        expect(updated.title, '新しい選挙');
        expect(updated.id, original.id);
        expect(updated.scale, original.scale);
      });

      test('updates voteCounts', () {
        final original = Election.sampleVillage();
        final updated = original.copyWith(
          voteCounts: {'candidate_1': 200},
        );

        expect(updated.voteCounts, {'candidate_1': 200});
      });

      test('updates winnerId', () {
        final original = Election.sampleVillage();
        final updated = original.copyWith(winnerId: 'candidate_2');

        expect(updated.winnerId, 'candidate_2');
      });

      test('returns same if no args', () {
        final original = Election.sampleVillage();
        expect(original.copyWith(), equals(original));
      });
    });

    group('props', () {
      test('contains all fields', () {
        final election = Election(
          id: 'test',
          title: 'test',
          scale: 'test',
          candidates: Candidate.samples(),
          voteCounts: {'a': 1},
          winnerId: 'a',
        );

        expect(election.props.length, 6);
        expect(election.props[0], 'test');
        expect(election.props[1], 'test');
        expect(election.props[2], 'test');
        expect(election.props[3], isA<List<Candidate>>());
        expect(election.props[4], {'a': 1});
        expect(election.props[5], 'a');
      });
    });
  });
}
