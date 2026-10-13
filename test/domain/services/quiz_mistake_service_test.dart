import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/services/quiz_mistake_service.dart';
import 'package:election_game/domain/services/quiz_service.dart';

void main() {
  final questions = <QuizQuestion>[
    QuizQuestion(
      id: 'q1',
      category: QuizCategory.system,
      question: '衆議院議員の任期は？',
      choices: const ['2年', '4年', '6年'],
      correctIndex: 1,
      explanation: '衆議院議員の任期は4年です。',
    ),
    QuizQuestion(
      id: 'q2',
      category: QuizCategory.policy,
      question: '奨学金の拡充はどの政策分野？',
      choices: const ['教育政策', '農業政策'],
      correctIndex: 0,
      explanation: '奨学金は教育政策の代表例です。',
    ),
  ];

  final now = DateTime(2026, 10, 13, 10, 0);

  QuizMistakeEntry entry({
    String questionId = 'q1',
    QuizCategory category = QuizCategory.system,
    int correctIndex = 1,
    int wrongCount = 1,
    int? lastSelectedIndex = 0,
    DateTime? lastWrongAt,
    DateTime? masteredAt,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: category,
      correctIndex: correctIndex,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex,
      lastWrongAt: lastWrongAt ?? now,
      masteredAt: masteredAt,
    );
  }

  group('QuizMistakeService.record', () {
    test('誤答は新規エントリとして記録される', () {
      final result = QuizService.grade(questions, [0, 1]);
      final entries = QuizMistakeService.record(
        const [],
        questions,
        result,
        now: now,
      );

      expect(entries.length, 2);
      expect(entries.every((e) => e.wrongCount == 1), isTrue);
      expect(entries.every((e) => e.lastWrongAt == now), isTrue);
      expect(entries.every((e) => e.isPending), isTrue);
      final q1 = entries.firstWhere((e) => e.questionId == 'q1');
      expect(q1.category, QuizCategory.system);
      expect(q1.correctIndex, 1);
      expect(q1.lastSelectedIndex, 0);
    });

    test('未回答（null）も誤答として記録される', () {
      final result = QuizService.grade(questions, [null, 0]);
      final entries = QuizMistakeService.record(
        const [],
        questions,
        result,
        now: now,
      );

      expect(entries.length, 1);
      expect(entries.single.questionId, 'q1');
      expect(entries.single.wasUnanswered, isTrue);
    });

    test('解答数が問題数より少ない場合、不足分は未回答として扱う', () {
      final result = QuizService.grade(questions, [0]);
      final entries = QuizMistakeService.record(
        const [],
        questions,
        result,
        now: now,
      );

      expect(entries.map((e) => e.questionId).toSet(), {'q1', 'q2'});
      expect(entries.firstWhere((e) => e.questionId == 'q2').wasUnanswered, isTrue);
    });

    test('正解した問題は記録されない', () {
      final result = QuizService.grade(questions, [1, 0]);
      final entries = QuizMistakeService.record(
        const [],
        questions,
        result,
        now: now,
      );

      expect(entries, isEmpty);
    });

    test('同じ問題に再度誤答すると誤答回数が加算され直近値が更新される', () {
      final first = QuizMistakeService.record(
        const [],
        questions,
        QuizService.grade(questions, [0, 0]),
        now: now,
      );
      final later = now.add(const Duration(days: 1));
      final second = QuizMistakeService.record(
        first,
        questions,
        QuizService.grade(questions, [2, 0]),
        now: later,
      );

      final q1 = second.firstWhere((e) => e.questionId == 'q1');
      expect(q1.wrongCount, 2);
      expect(q1.lastSelectedIndex, 2);
      expect(q1.lastWrongAt, later);
    });

    test('正解すると既存エントリが克服済みになる（誤答履歴は保持）', () {
      final first = QuizMistakeService.record(
        const [],
        questions,
        QuizService.grade(questions, [0, 0]),
        now: now,
      );
      final masteredAt = now.add(const Duration(days: 2));
      final second = QuizMistakeService.record(
        first,
        questions,
        QuizService.grade(questions, [1, 0]),
        now: masteredAt,
      );

      final q1 = second.firstWhere((e) => e.questionId == 'q1');
      expect(q1.isMastered, isTrue);
      expect(q1.masteredAt, masteredAt);
      expect(q1.wrongCount, 1);
      expect(q1.lastSelectedIndex, 0);
    });

    test('克服後に再び誤答すると未克服へ戻り回数が増える', () {
      final mastered = entry(masteredAt: now);
      final reWrong = QuizMistakeService.record(
        [mastered],
        questions,
        QuizService.grade(questions, [0, 0]),
        now: now.add(const Duration(days: 3)),
      );

      final q1 = reWrong.firstWhere((e) => e.questionId == 'q1');
      expect(q1.isPending, isTrue);
      expect(q1.wrongCount, 2);
    });

    test('問題バンクに無いIDのエントリは変更せず保持する', () {
      final ghost = entry(questionId: 'legacy_9', wrongCount: 5);
      final result = QuizMistakeService.record(
        [ghost],
        questions,
        QuizService.grade(questions, [0, 0]),
        now: now,
      );

      final preserved = result.firstWhere((e) => e.questionId == 'legacy_9');
      expect(preserved.wrongCount, 5);
      expect(preserved, ghost);
    });

    test('結果は決定論的な並び（未克服優先・誤答回数降順）になる', () {
      final existing = [
        entry(questionId: 'q2', category: QuizCategory.policy, correctIndex: 0, wrongCount: 1),
        entry(questionId: 'q1', correctIndex: 1, wrongCount: 4),
      ];
      // q1 を正解＝克服、q2 を誤答＝加算
      final result = QuizMistakeService.record(
        existing,
        questions,
        QuizService.grade(questions, [1, 1]),
        now: now.add(const Duration(hours: 1)),
      );

      expect(result.map((e) => e.questionId).toList(), ['q2', 'q1']);
      expect(result.first.isPending, isTrue);
      expect(result.last.isMastered, isTrue);
    });

    test('入力リストは変更しない', () {
      final existing = [entry(questionId: 'q1')];
      QuizMistakeService.record(
        existing,
        questions,
        QuizService.grade(questions, [0, 0]),
        now: now,
      );
      expect(existing.single.wrongCount, 1);
    });
  });

  group('QuizMistakeService.sort', () {
    test('未克服は誤答回数の多い順、同数は直近の誤答が新しい順', () {
      final entries = [
        entry(questionId: 'a', wrongCount: 1, lastWrongAt: now),
        entry(questionId: 'b', wrongCount: 3, lastWrongAt: now),
        entry(questionId: 'c', wrongCount: 1, lastWrongAt: now.add(const Duration(days: 1))),
        entry(questionId: 'd', wrongCount: 1, lastWrongAt: now),
      ];
      final sorted = QuizMistakeService.sort(entries);
      expect(sorted.map((e) => e.questionId).toList(), ['b', 'c', 'a', 'd']);
    });

    test('克服済みは克服日時の新しい順で末尾に並ぶ', () {
      final entries = [
        entry(questionId: 'p', wrongCount: 2),
        entry(questionId: 'm1', masteredAt: now.add(const Duration(days: 1))),
        entry(questionId: 'm2', masteredAt: now.add(const Duration(days: 5))),
      ];
      final sorted = QuizMistakeService.sort(entries);
      expect(sorted.map((e) => e.questionId).toList(), ['p', 'm2', 'm1']);
    });

    test('完全に同条件なら問題ID昇順', () {
      final entries = [
        entry(questionId: 'z', wrongCount: 2),
        entry(questionId: 'a', wrongCount: 2),
      ];
      expect(
        QuizMistakeService.sort(entries).map((e) => e.questionId).toList(),
        ['a', 'z'],
      );
    });

    test('入力リストは変更しない', () {
      final entries = [
        entry(questionId: 'z', wrongCount: 2),
        entry(questionId: 'a', wrongCount: 2),
      ];
      QuizMistakeService.sort(entries);
      expect(entries.map((e) => e.questionId).toList(), ['z', 'a']);
    });
  });

  group('QuizMistakeService 絞り込み', () {
    final entries = [
      entry(questionId: 'p', category: QuizCategory.policy, correctIndex: 0),
      entry(
        questionId: 'm',
        category: QuizCategory.system,
        masteredAt: now.add(const Duration(hours: 1)),
      ),
    ];

    test('pending は未克服のみ', () {
      expect(QuizMistakeService.pending(entries).map((e) => e.questionId), ['p']);
    });

    test('mastered は克服済みのみ', () {
      expect(QuizMistakeService.mastered(entries).map((e) => e.questionId), ['m']);
    });

    test('filterByCategory はカテゴリ一致のみ（null は全件）', () {
      expect(
        QuizMistakeService.filterByCategory(entries, QuizCategory.policy)
            .map((e) => e.questionId),
        ['p'],
      );
      expect(QuizMistakeService.filterByCategory(entries, null).length, 2);
    });
  });

  group('QuizMistakeService.buildReviewQuestions', () {
    test('未克服の問題のみを復習順で返す', () {
      final entries = [
        entry(questionId: 'q2', category: QuizCategory.policy, correctIndex: 0, wrongCount: 3),
        entry(questionId: 'q1', correctIndex: 1, wrongCount: 1),
        entry(
          questionId: 'q1',
          wrongCount: 9,
          masteredAt: now,
        ),
      ];
      final review = QuizMistakeService.buildReviewQuestions(entries, bank: questions);
      expect(review.map((q) => q.id).toList(), ['q2', 'q1']);
    });

    test('問題バンクに無いIDは無視する', () {
      final entries = [entry(questionId: 'legacy_unknown', wrongCount: 5)];
      expect(
        QuizMistakeService.buildReviewQuestions(entries, bank: questions),
        isEmpty,
      );
    });

    test('未克服が無ければ空', () {
      final entries = [entry(questionId: 'q1', masteredAt: now)];
      expect(
        QuizMistakeService.buildReviewQuestions(entries, bank: questions),
        isEmpty,
      );
    });
  });
}
