import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/domain/models/candidate_rating.dart';
import 'package:election_game/domain/services/rating_service.dart';

void main() {
  group('RatingService', () {
    setUp(() {
      // SharedPreferences のモック初期化
      SharedPreferences.setMockInitialValues({});
    });

    test('評価を保存して取得できる', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rating = CandidateRating(
        candidateId: 'candidate_1',
        candidateName: '山田太郎',
        rating: 4,
        ratedAt: now,
      );

      await RatingService.saveRating(rating);

      final retrieved = await RatingService.getRating('candidate_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.candidateId, 'candidate_1');
      expect(retrieved.candidateName, '山田太郎');
      expect(retrieved.rating, 4);
    });

    test('存在しない候補者IDの評価は null を返す', () async {
      final retrieved = await RatingService.getRating('unknown_candidate');
      expect(retrieved, isNull);
    });

    test('評価を更新できる（上書き保存）', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rating1 = CandidateRating(
        candidateId: 'candidate_1',
        candidateName: '山田太郎',
        rating: 3,
        ratedAt: now,
      );
      await RatingService.saveRating(rating1);

      // 評価を上書き
      final rating2 = rating1.copyWith(rating: 5);
      await RatingService.saveRating(rating2);

      final retrieved = await RatingService.getRating('candidate_1');
      expect(retrieved!.rating, 5);
    });

    test('全評価を取得できる', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await RatingService.saveRating(CandidateRating(
        candidateId: 'candidate_1',
        candidateName: '山田太郎',
        rating: 4,
        ratedAt: now,
      ));
      await RatingService.saveRating(CandidateRating(
        candidateId: 'candidate_2',
        candidateName: '佐藤花子',
        rating: 5,
        ratedAt: now,
      ));
      await RatingService.saveRating(CandidateRating(
        candidateId: 'candidate_3',
        candidateName: '鈴木一郎',
        rating: 2,
        ratedAt: now,
      ));

      final allRatings = await RatingService.getAllRatings();
      expect(allRatings.length, 3);
    });

    test('全評価を削除できる', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await RatingService.saveRating(CandidateRating(
        candidateId: 'candidate_1',
        candidateName: '山田太郎',
        rating: 4,
        ratedAt: now,
      ));
      await RatingService.saveRating(CandidateRating(
        candidateId: 'candidate_2',
        candidateName: '佐藤花子',
        rating: 5,
        ratedAt: now,
      ));

      await RatingService.clearAllRatings();

      final allRatings = await RatingService.getAllRatings();
      expect(allRatings, isEmpty);
    });
  });
}
