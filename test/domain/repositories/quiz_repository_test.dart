import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/domain/models/quiz_result.dart';
import 'package:election_game/domain/repositories/quiz_repository.dart';

void main() {
  group('QuizRepository', () {
    const repository = QuizRepository();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('記録が無ければ loadBest は null・attempts は 0', () async {
      expect(await repository.loadBest(), isNull);
      expect(await repository.loadAttempts(), 0);
    });

    test('採点結果を保存して読み戻せる', () async {
      final result = QuizResult(
        answers: const [0, 0, 1, 1],
        correctIndexes: const [0, 1, 1, 0],
      );
      final best = await repository.saveResult(result);

      expect(best.correctCount, 2);
      expect(best.total, 4);
      expect(best.attempts, 1);

      final loaded = await repository.loadBest();
      expect(loaded, isNotNull);
      expect(loaded!.correctCount, 2);
      expect(loaded.total, 4);
      expect(loaded.attempts, 1);
      expect(await repository.loadAttempts(), 1);
    });

    test('正答数が上回ったときのみベストを更新する', () async {
      final low = QuizResult(
        answers: const [0, 1],
        correctIndexes: const [0, 0],
      );
      final high = QuizResult(
        answers: const [0, 0],
        correctIndexes: const [0, 0],
      );

      await repository.saveResult(low);
      await repository.saveResult(high);

      final best = await repository.loadBest();
      expect(best!.correctCount, 2);
      expect(best.total, 2);
      expect(best.attempts, 2);
    });

    test('低いスコアではベストを下げない（挑戦回数のみ増える）', () async {
      final high = QuizResult(
        answers: const [0, 0],
        correctIndexes: const [0, 0],
      );
      final low = QuizResult(
        answers: const [0, 1],
        correctIndexes: const [0, 0],
      );

      await repository.saveResult(high);
      await repository.saveResult(low);

      final best = await repository.loadBest();
      expect(best!.correctCount, 2);
      expect(best.attempts, 2);
      expect(await repository.loadAttempts(), 2);
    });

    test('同点ではベストを保持する', () async {
      final first = QuizResult(
        answers: const [0, 1],
        correctIndexes: const [0, 0],
      );
      final second = QuizResult(
        answers: const [1, 0],
        correctIndexes: const [1, 1],
      );

      await repository.saveResult(first);
      final best = await repository.saveResult(second);

      expect(best.correctCount, 1);
      expect(best.total, 2);
      expect(best.attempts, 2);
    });

    test('破損データ（負値）は null にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        QuizRepository.bestCorrectKey: -1,
        QuizRepository.bestTotalKey: 5,
      });
      expect(await repository.loadBest(), isNull);
    });

    test('破損データ（正答数が出題数を超過）は null にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        QuizRepository.bestCorrectKey: 5,
        QuizRepository.bestTotalKey: 2,
      });
      expect(await repository.loadBest(), isNull);
    });

    test('破損データ（出題数0）は null にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        QuizRepository.bestCorrectKey: 0,
        QuizRepository.bestTotalKey: 0,
      });
      expect(await repository.loadBest(), isNull);
    });

    test('clear ですべての記録を消す', () async {
      final result = QuizResult(
        answers: const [0],
        correctIndexes: const [0],
      );
      await repository.saveResult(result);
      await repository.clear();

      expect(await repository.loadBest(), isNull);
      expect(await repository.loadAttempts(), 0);
    });
  });
}
