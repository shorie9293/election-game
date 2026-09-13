import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/services/quiz_service.dart';

void main() {
  group('QuizService.defaultQuestions', () {
    test('8問以上の有効な問題を返す（不変条件を満たす）', () {
      final questions = QuizService.defaultQuestions();
      expect(questions.length, greaterThanOrEqualTo(8));
      for (final q in questions) {
        expect(q.choices.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, inInclusiveRange(0, q.choices.length - 1));
        expect(q.explanation, isNotEmpty);
      }
    });

    test('IDは重複しない', () {
      final ids = QuizService.defaultQuestions().map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('選挙制度と政策の両カテゴリを含む', () {
      final questions = QuizService.defaultQuestions();
      final categories = questions.map((q) => q.category).toSet();
      expect(categories, containsAll(QuizCategory.values));
    });

    test('毎回同じ内容を返す（決定的）', () {
      final first = QuizService.defaultQuestions();
      final second = QuizService.defaultQuestions();
      expect(
        first.map((q) => q.id).toList(),
        second.map((q) => q.id).toList(),
      );
    });
  });

  group('QuizService.grade', () {
    final questions = [
      QuizQuestion(
        id: 'a',
        category: QuizCategory.system,
        question: 'Q1',
        choices: const ['x', 'y'],
        correctIndex: 0,
        explanation: 'A1',
      ),
      QuizQuestion(
        id: 'b',
        category: QuizCategory.policy,
        question: 'Q2',
        choices: const ['x', 'y', 'z'],
        correctIndex: 2,
        explanation: 'A2',
      ),
    ];

    test('正解・不正解を正しく採点する', () {
      final result = QuizService.grade(questions, const [0, 1]);
      expect(result.correctCount, 1);
      expect(result.total, 2);
      expect(result.percent, 50);
    });

    test('未回答(null)は不正解として扱う', () {
      final result = QuizService.grade(questions, const [null, null]);
      expect(result.correctCount, 0);
      expect(result.missedIndexes, [0, 1]);
    });

    test('解答が問題数より短い場合、不足分は未回答扱い', () {
      final result = QuizService.grade(questions, const [0]);
      expect(result.total, 2);
      expect(result.correctCount, 1);
      expect(result.answers[1], isNull);
    });

    test('解答が問題数より長い場合、余剰分は無視する', () {
      final result = QuizService.grade(questions, const [0, 2, 1, 0]);
      expect(result.total, 2);
      expect(result.correctCount, 2);
    });

    test('範囲外インデックスは不正解として扱う（例外にしない）', () {
      final result = QuizService.grade(questions, const [99, 2]);
      expect(result.correctCount, 1);
      expect(result.missedIndexes, [0]);
    });

    test('問題が空なら出題数0の結果を返す', () {
      final result = QuizService.grade(const [], const []);
      expect(result.total, 0);
      expect(result.rankLabel, '未挑戦');
    });

    test('全問正解は合格・パーフェクト', () {
      final result = QuizService.grade(questions, const [0, 2]);
      expect(result.isPerfect, isTrue);
      expect(result.isPassed, isTrue);
      expect(result.rankLabel, '選挙マスター');
    });
  });

  group('QuizService.questionsByCategory', () {
    test('カテゴリで絞り込み元順序を保つ', () {
      final questions = QuizService.defaultQuestions();
      final policies =
          QuizService.questionsByCategory(questions, QuizCategory.policy);
      expect(policies, isNotEmpty);
      expect(policies.every((q) => q.category == QuizCategory.policy), isTrue);

      final expectedIds = questions
          .where((q) => q.category == QuizCategory.policy)
          .map((q) => q.id)
          .toList();
      expect(policies.map((q) => q.id).toList(), expectedIds);
    });
  });

  group('QuizService.questionsFor', () {
    test('カテゴリ未指定なら全問を返す', () {
      expect(
        QuizService.questionsFor().length,
        QuizService.defaultQuestions().length,
      );
    });

    test('カテゴリ指定ならそのカテゴリのみ返す', () {
      final systemQuestions =
          QuizService.questionsFor(category: QuizCategory.system);
      expect(systemQuestions, isNotEmpty);
      expect(
        systemQuestions.every((q) => q.category == QuizCategory.system),
        isTrue,
      );
    });
  });
}
