import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/prediction/domain/election_prediction.dart';
import 'package:election_game/features/prediction/domain/prediction_service.dart';

Candidate _c(String id) => Candidate(
      id: id,
      name: '候補$id',
      portraitKey: 'p_$id',
      faction: 'f',
      personality: 'p',
      policies: const [],
    );

Election _election({
  Map<String, int>? voteCounts,
  String? winnerId,
  List<Candidate>? candidates,
}) {
  return Election(
    id: 'e1',
    title: '町長選',
    scale: ElectionScale.town,
    candidates: candidates ?? [_c('a'), _c('b'), _c('c')],
    voteCounts: voteCounts,
    winnerId: winnerId,
  );
}

ElectionPrediction _prediction({
  String winner = 'a',
  int share = 50,
}) {
  return ElectionPrediction(
    electionId: 'e1',
    predictedWinnerId: winner,
    predictedShare: share,
    createdAt: 1,
  );
}

void main() {
  group('actualShare', () {
    test('四捨五入される（1/3 → 33%）', () {
      final e = _election(voteCounts: {'a': 1, 'b': 1, 'c': 1});
      expect(PredictionService.actualShare(e, 'a'), 33);
    });

    test('四捨五入される（2/3 → 67%）', () {
      final e = _election(voteCounts: {'a': 2, 'b': 1});
      expect(PredictionService.actualShare(e, 'a'), 67);
    });

    test('総数100なら票数と一致', () {
      final e = _election(voteCounts: {'a': 40, 'b': 35, 'c': 25});
      expect(PredictionService.actualShare(e, 'a'), 40);
      expect(PredictionService.actualShare(e, 'c'), 25);
    });

    test('total==0なら0を返す', () {
      final e = _election(voteCounts: {});
      expect(PredictionService.actualShare(e, 'a'), 0);
    });

    test('voteCounts nullでArgumentError', () {
      final e = _election();
      expect(() => PredictionService.actualShare(e, 'a'), throwsArgumentError);
    });
  });

  group('ranking', () {
    test('得票数降順で返す', () {
      final e = _election(voteCounts: {'a': 10, 'b': 30, 'c': 20});
      expect(PredictionService.ranking(e), ['b', 'c', 'a']);
    });

    test('同数は宣言順を保つ（安定ソート）', () {
      // b, c が同数30 → 宣言順 a,b,c のうち b が c より先
      final e = _election(voteCounts: {'a': 10, 'b': 30, 'c': 30});
      expect(PredictionService.ranking(e), ['b', 'c', 'a']);
    });

    test('同数タイブレークの逆順も宣言順を保つ', () {
      // a, c が同数20 → 宣言順で a が先
      final e = _election(voteCounts: {'a': 20, 'b': 30, 'c': 20});
      expect(PredictionService.ranking(e), ['b', 'a', 'c']);
    });

    test('voteCounts nullでArgumentError', () {
      final e = _election();
      expect(() => PredictionService.ranking(e), throwsArgumentError);
    });
  });

  group('evaluate', () {
    test('的中＋誤差0でscore 100・完璧', () {
      final e = _election(
        voteCounts: {'a': 60, 'b': 30, 'c': 10},
        winnerId: 'a',
      );
      final outcome = PredictionService.evaluate(_prediction(winner: 'a', share: 60), e);
      expect(outcome.winnerHit, isTrue);
      expect(outcome.shareError, 0);
      expect(outcome.shareWithinTolerance, isTrue);
      expect(outcome.score, 100);
      expect(outcome.accuracyLabel, '完璧');
    });

    test('的中＋誤差35でscore 65・まずまず', () {
      final e = _election(
        voteCounts: {'a': 85, 'b': 10, 'c': 5},
        winnerId: 'a',
      );
      final outcome = PredictionService.evaluate(_prediction(winner: 'a', share: 50), e);
      expect(outcome.winnerHit, isTrue);
      expect(outcome.shareError, 35);
      expect(outcome.shareWithinTolerance, isFalse);
      expect(outcome.score, 65);
      expect(outcome.accuracyLabel, 'まずまず');
    });

    test('的中＋誤差25でscore 75・大当たり', () {
      final e = _election(
        voteCounts: {'a': 75, 'b': 15, 'c': 10},
        winnerId: 'a',
      );
      final outcome = PredictionService.evaluate(_prediction(winner: 'a', share: 50), e);
      expect(outcome.score, 75);
      expect(outcome.accuracyLabel, '大当たり');
    });

    test('的中＋誤差45でscore 55・まずまず', () {
      final e = _election(
        voteCounts: {'a': 95, 'b': 3, 'c': 2},
        winnerId: 'a',
      );
      final outcome = PredictionService.evaluate(_prediction(winner: 'a', share: 50), e);
      expect(outcome.score, 55);
      expect(outcome.accuracyLabel, 'まずまず');
    });

    test('外れ＋誤差50でscore 0・外れ', () {
      final e = _election(
        voteCounts: {'a': 100},
        winnerId: 'a',
      );
      final outcome = PredictionService.evaluate(_prediction(winner: 'b', share: 50), e);
      expect(outcome.winnerHit, isFalse);
      expect(outcome.shareError, 50);
      expect(outcome.score, 0);
      expect(outcome.accuracyLabel, '外れ');
    });

    test('外れ＋誤差20でscore 30・惜しい', () {
      final e = _election(
        voteCounts: {'a': 70, 'b': 20, 'c': 10},
        winnerId: 'a',
      );
      final outcome = PredictionService.evaluate(_prediction(winner: 'b', share: 50), e);
      expect(outcome.winnerHit, isFalse);
      expect(outcome.shareError, 20);
      expect(outcome.score, 30);
      expect(outcome.accuracyLabel, '惜しい');
    });

    test('未完了選挙でArgumentError（voteCounts null）', () {
      final e = _election(winnerId: 'a');
      expect(
        () => PredictionService.evaluate(_prediction(), e),
        throwsArgumentError,
      );
    });

    test('未完了選挙でArgumentError（winnerId null）', () {
      final e = _election(voteCounts: {'a': 50, 'b': 50});
      expect(
        () => PredictionService.evaluate(_prediction(), e),
        throwsArgumentError,
      );
    });

    test('未知のpredictedWinnerIdでArgumentError', () {
      final e = _election(
        voteCounts: {'a': 60, 'b': 40},
        winnerId: 'a',
      );
      expect(
        () => PredictionService.evaluate(_prediction(winner: 'zzz'), e),
        throwsArgumentError,
      );
    });

    test('actualRankingが降順で入る', () {
      final e = _election(
        voteCounts: {'a': 40, 'b': 50, 'c': 10},
        winnerId: 'b',
      );
      final outcome = PredictionService.evaluate(_prediction(winner: 'b'), e);
      expect(outcome.actualWinnerId, 'b');
      expect(outcome.actualShare, 50);
      expect(outcome.actualRanking, ['b', 'a', 'c']);
    });
  });
}