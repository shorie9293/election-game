import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_question.dart';

void main() {
  group('QuizQuestion', () {
    QuizQuestion build({
      String id = 'q1',
      QuizCategory category = QuizCategory.system,
      String question = '衆議院議員の任期は？',
      List<String> choices = const ['2年', '4年', '6年'],
      int correctIndex = 1,
      String explanation = '衆議院議員の任期は4年です。',
    }) {
      return QuizQuestion(
        id: id,
        category: category,
        question: question,
        choices: choices,
        correctIndex: correctIndex,
        explanation: explanation,
      );
    }

    test('正しい値で生成でき、各フィールドが保持される', () {
      final q = build();
      expect(q.id, 'q1');
      expect(q.category, QuizCategory.system);
      expect(q.question, '衆議院議員の任期は？');
      expect(q.choices, ['2年', '4年', '6年']);
      expect(q.correctIndex, 1);
      expect(q.explanation, contains('4年'));
    });

    test('id が空なら ArgumentError', () {
      expect(() => build(id: '  '), throwsArgumentError);
    });

    test('問題文が空なら ArgumentError', () {
      expect(() => build(question: ''), throwsArgumentError);
    });

    test('解説が空なら ArgumentError', () {
      expect(() => build(explanation: ''), throwsArgumentError);
    });

    test('選択肢が2件未満なら ArgumentError', () {
      expect(() => build(choices: const ['ひとつだけ'], correctIndex: 0),
          throwsArgumentError);
    });

    test('正解インデックスが範囲外なら ArgumentError', () {
      expect(() => build(correctIndex: 3), throwsArgumentError);
      expect(() => build(correctIndex: -1), throwsArgumentError);
    });

    test('isCorrect は未回答(null)・別選択肢・範囲外を不正解とする', () {
      final q = build();
      expect(q.isCorrect(1), isTrue);
      expect(q.isCorrect(0), isFalse);
      expect(q.isCorrect(null), isFalse);
      expect(q.isCorrect(99), isFalse);
    });

    test('copyWith は指定フィールドのみ差し替える', () {
      final q = build();
      final updated = q.copyWith(question: '参議院議員の任期は？', correctIndex: 2);
      expect(updated.question, '参議院議員の任期は？');
      expect(updated.correctIndex, 2);
      expect(updated.id, q.id);
      expect(updated.choices, q.choices);
    });

    test('copyWith で不変条件を破ると ArgumentError', () {
      final q = build();
      expect(() => q.copyWith(correctIndex: 10), throwsArgumentError);
    });

    test('同値なら等しい（Equatable）', () {
      expect(build(), build());
      expect(build(), isNot(build(id: 'q2')));
    });

    test('choices は外部から変更できない（不変リスト）', () {
      final q = build();
      expect(() => q.choices.add('8年'), throwsUnsupportedError);
    });
  });

  group('QuizCategory', () {
    test('日本語ラベルを持つ', () {
      expect(QuizCategory.system.label, '選挙制度');
      expect(QuizCategory.policy.label, '政策');
    });
  });
}
