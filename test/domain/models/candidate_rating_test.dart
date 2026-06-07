import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate_rating.dart';

void main() {
  group('CandidateRating', () {
    test('toJson/fromJson で正しく変換できる', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rating = CandidateRating(
        candidateId: 'candidate_1',
        candidateName: '山田太郎',
        rating: 4,
        ratedAt: now,
      );

      final json = rating.toJson();
      expect(json['candidateId'], 'candidate_1');
      expect(json['candidateName'], '山田太郎');
      expect(json['rating'], 4);
      expect(json['ratedAt'], now);

      final restored = CandidateRating.fromJson(json);
      expect(restored.candidateId, rating.candidateId);
      expect(restored.candidateName, rating.candidateName);
      expect(restored.rating, rating.rating);
      expect(restored.ratedAt, rating.ratedAt);
    });

    test('rating は 1〜5 の範囲であること', () {
      expect(
        () => CandidateRating(
          candidateId: 'test',
          candidateName: 'test',
          rating: 0,
          ratedAt: 123,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => CandidateRating(
          candidateId: 'test',
          candidateName: 'test',
          rating: 6,
          ratedAt: 123,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith で評価を更新できる', () {
      final original = CandidateRating(
        candidateId: 'candidate_1',
        candidateName: '山田太郎',
        rating: 3,
        ratedAt: 1000,
      );

      final updated = original.copyWith(rating: 5);
      expect(updated.rating, 5);
      expect(updated.candidateId, original.candidateId);
      expect(updated.candidateName, original.candidateName);
      expect(updated.ratedAt, original.ratedAt);
    });
  });
}
