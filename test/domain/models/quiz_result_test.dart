import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_result.dart';

void main() {
  group('QuizResult', () {
    test('採点: 正答数・出題数・正答率・パーセント', () {
      final r = QuizResult(
        answers: const [1, 0, 2, null],
        correctIndexes: const [1, 1, 2, 0],
      );
      expect(r.total, 4);
      expect(r.correctCount, 2);
      expect(r.ratio, 0.5);
      expect(r.percent, 50);
      expect(r.isPassed, isFalse);
    });

    test('合格判定は70%以上', () {
      final passed = QuizResult(
        answers: const [0, 0, 0, 1],
        correctIndexes: const [0, 0, 0, 9],
      );
      expect(passed.ratio, 0.75);
      expect(passed.isPassed, isTrue);
    });

    test('70%ちょうどは合格', () {
      final r = QuizResult(
        answers: const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        correctIndexes: const [0, 0, 0, 0, 0, 0, 0, 1, 1, 1],
      );
      expect(r.ratio, 0.7);
      expect(r.isPassed, isTrue);
    });

    test('missedIndexes は未回答・範囲外解答も含める', () {
      final r = QuizResult(
        answers: const [0, null, 99],
        correctIndexes: const [0, 1, 2],
      );
      expect(r.missedIndexes, [1, 2]);
    });

    test('全問正解は isPerfect かつ rankLabel は選挙マスター', () {
      final r = QuizResult(
        answers: const [1, 1],
        correctIndexes: const [1, 1],
      );
      expect(r.isPerfect, isTrue);
      expect(r.rankLabel, '選挙マスター');
      expect(r.missedIndexes, isEmpty);
    });

    test('rankLabel の5段階', () {
      String labelOf(int correct, int total) {
        return QuizResult(
          answers: List<int?>.generate(total, (i) => i < correct ? 0 : 1),
          correctIndexes: List<int>.filled(total, 0),
        ).rankLabel;
      }

      expect(labelOf(10, 10), '選挙マスター');
      expect(labelOf(8, 10), 'よく理解している');
      expect(labelOf(7, 10), '合格ライン');
      expect(labelOf(5, 10), 'もう一息');
      expect(labelOf(4, 10), '復習しよう');
    });

    test('出題数0なら ratio 0・不合格・未挑戦', () {
      final r = QuizResult(answers: const [], correctIndexes: const []);
      expect(r.total, 0);
      expect(r.correctCount, 0);
      expect(r.ratio, 0.0);
      expect(r.percent, 0);
      expect(r.isPassed, isFalse);
      expect(r.isPerfect, isFalse);
      expect(r.rankLabel, '未挑戦');
    });

    test('解答数と正解数が一致しなければ ArgumentError', () {
      expect(
        () => QuizResult(answers: const [1], correctIndexes: const [1, 2]),
        throwsArgumentError,
      );
    });

    test('同値なら等しい（Equatable）', () {
      final a = QuizResult(answers: const [0], correctIndexes: const [0]);
      final b = QuizResult(answers: const [0], correctIndexes: const [0]);
      expect(a, b);
    });
  });

  group('QuizBestScore', () {
    test('hasRecord は total>0 で真', () {
      expect(QuizBestScore.empty.hasRecord, isFalse);
      expect(
        const QuizBestScore(correctCount: 3, total: 10).hasRecord,
        isTrue,
      );
    });

    test('percent は正答率を四捨五入する', () {
      expect(const QuizBestScore(correctCount: 7, total: 10).percent, 70);
      expect(const QuizBestScore(correctCount: 2, total: 3).percent, 67);
    });

    test('copyWith は指定フィールドのみ差し替える', () {
      const best = QuizBestScore(correctCount: 5, total: 10, attempts: 2);
      final updated = best.copyWith(attempts: 3);
      expect(updated.correctCount, 5);
      expect(updated.total, 10);
      expect(updated.attempts, 3);
    });
  });
}
