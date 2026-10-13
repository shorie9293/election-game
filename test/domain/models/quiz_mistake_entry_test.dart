import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';

void main() {
  final base = DateTime(2026, 10, 13, 9, 30);

  QuizMistakeEntry build({
    String questionId = 'system_1',
    QuizCategory category = QuizCategory.system,
    int correctIndex = 2,
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
      lastWrongAt: lastWrongAt ?? base,
      masteredAt: masteredAt,
    );
  }

  group('QuizMistakeEntry 不変条件', () {
    test('問題IDが空なら ArgumentError', () {
      expect(() => build(questionId: '  '), throwsArgumentError);
    });

    test('誤答回数が0以下なら ArgumentError', () {
      expect(() => build(wrongCount: 0), throwsArgumentError);
      expect(() => build(wrongCount: -1), throwsArgumentError);
    });

    test('正解インデックスが負なら ArgumentError', () {
      expect(() => build(correctIndex: -1), throwsArgumentError);
    });

    test('直近の誤答選択が負なら ArgumentError', () {
      expect(() => build(lastSelectedIndex: -1), throwsArgumentError);
    });

    test('克服日時が誤答日時より前なら ArgumentError', () {
      expect(
        () => build(masteredAt: base.subtract(const Duration(days: 1))),
        throwsArgumentError,
      );
    });

    test('克服日時が誤答日時と同じなら許容される', () {
      final entry = build(masteredAt: base);
      expect(entry.isMastered, isTrue);
    });
  });

  group('QuizMistakeEntry getter', () {
    test(' masteredAt が null なら未克服（要復習）', () {
      final entry = build();
      expect(entry.isPending, isTrue);
      expect(entry.isMastered, isFalse);
    });

    test('masteredAt があれば克服済み', () {
      final entry = build(masteredAt: base.add(const Duration(hours: 1)));
      expect(entry.isMastered, isTrue);
      expect(entry.isPending, isFalse);
    });

    test('lastSelectedIndex が null なら未回答の誤答', () {
      expect(build(lastSelectedIndex: null).wasUnanswered, isTrue);
      expect(build(lastSelectedIndex: 1).wasUnanswered, isFalse);
    });
  });

  group('QuizMistakeEntry copyWith', () {
    test('指定したフィールドのみ更新する', () {
      final entry = build();
      final updated = entry.copyWith(wrongCount: 3);
      expect(updated.wrongCount, 3);
      expect(updated.questionId, entry.questionId);
      expect(updated.lastWrongAt, entry.lastWrongAt);
    });

    test('clearMastered で克服を未克服へ戻せる', () {
      final mastered = build(masteredAt: base.add(const Duration(hours: 1)));
      final reverted = mastered.copyWith(clearMastered: true);
      expect(reverted.isPending, isTrue);
    });

    test('clearMastered と masteredAt の併用時は clearMastered が勝つ', () {
      final mastered = build(masteredAt: base.add(const Duration(hours: 1)));
      final reverted = mastered.copyWith(
        clearMastered: true,
        masteredAt: base.add(const Duration(hours: 2)),
      );
      expect(reverted.isPending, isTrue);
    });
  });

  group('QuizMistakeEntry JSON 往復', () {
    test('未克服エントリは往復しても等価', () {
      final entry = build();
      final restored = QuizMistakeEntry.fromJson(entry.toJson());
      expect(restored, entry);
    });

    test('克服済みエントリは往復しても等価', () {
      final entry = build(masteredAt: base.add(const Duration(minutes: 30)));
      final restored = QuizMistakeEntry.fromJson(entry.toJson());
      expect(restored, entry);
    });

    test('未回答の誤答も往復できる', () {
      final entry = build(lastSelectedIndex: null);
      expect(QuizMistakeEntry.fromJson(entry.toJson()), entry);
    });

    test('未知のカテゴリは FormatException', () {
      final json = build().toJson()..['category'] = 'unknown';
      expect(() => QuizMistakeEntry.fromJson(json), throwsFormatException);
    });

    test('日時が解釈不能なら FormatException', () {
      final json = build().toJson()..['lastWrongAt'] = 'not-a-date';
      expect(() => QuizMistakeEntry.fromJson(json), throwsFormatException);
    });

    test('問題IDが欠落なら FormatException', () {
      final json = build().toJson()..remove('questionId');
      expect(() => QuizMistakeEntry.fromJson(json), throwsFormatException);
    });

    test('誤答回数が文字列なら FormatException', () {
      final json = build().toJson()..['wrongCount'] = '1';
      expect(() => QuizMistakeEntry.fromJson(json), throwsFormatException);
    });
  });

  test('等価比較は全フィールドを対象とする', () {
    expect(build(), build());
    expect(build(wrongCount: 2), isNot(build()));
  });
}
