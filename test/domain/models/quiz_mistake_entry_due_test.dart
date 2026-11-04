import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';

/// 間隔反復用フィールド（dueAt / reviewIntervalDays）の試練。
///
/// 既存の quiz_mistake_entry_test.dart は後方互換の観点から書き換えず、
/// 新フィールドの検証は本ファイルに集約する。
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
    DateTime? dueAt,
    int reviewIntervalDays = 0,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: category,
      correctIndex: correctIndex,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex,
      lastWrongAt: lastWrongAt ?? base,
      masteredAt: masteredAt,
      dueAt: dueAt,
      reviewIntervalDays: reviewIntervalDays,
    );
  }

  group('dueAt / reviewIntervalDays 既定値', () {
    test('dueAt 未指定なら lastWrongAt を採用する', () {
      final entry = build();
      expect(entry.dueAt, base);
      expect(entry.reviewIntervalDays, 0);
    });

    test('dueAt を指定すればその値を持つ', () {
      final due = base.add(const Duration(days: 3));
      final entry = build(dueAt: due, reviewIntervalDays: 3);
      expect(entry.dueAt, due);
      expect(entry.reviewIntervalDays, 3);
    });
  });

  group('dueAt / reviewIntervalDays 不変条件', () {
    test('dueAt が lastWrongAt より前なら ArgumentError', () {
      expect(
        () => build(dueAt: base.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });

    test('dueAt が lastWrongAt と同じなら許容される', () {
      expect(build(dueAt: base).dueAt, base);
    });

    test('reviewIntervalDays が負なら ArgumentError', () {
      expect(() => build(reviewIntervalDays: -1), throwsArgumentError);
    });
  });

  group('dueAt / reviewIntervalDays の JSON 往復', () {
    test('新フィールドを含めて往復しても等価', () {
      final entry = build(
        dueAt: base.add(const Duration(days: 7)),
        reviewIntervalDays: 7,
      );
      final restored = QuizMistakeEntry.fromJson(entry.toJson());
      expect(restored, entry);
      expect(restored.dueAt, entry.dueAt);
      expect(restored.reviewIntervalDays, 7);
    });

    test('toJson は dueAt を ISO8601・reviewIntervalDays を int で持つ', () {
      final entry = build(
        dueAt: base.add(const Duration(days: 1)),
        reviewIntervalDays: 1,
      );
      final json = entry.toJson();
      expect(json['dueAt'], entry.dueAt.toIso8601String());
      expect(json['reviewIntervalDays'], isA<int>());
    });

    test('旧 JSON（dueAt 欠落）は lastWrongAt で読める', () {
      final json = build().toJson()
        ..remove('dueAt')
        ..remove('reviewIntervalDays');
      final restored = QuizMistakeEntry.fromJson(json);
      expect(restored.dueAt, base);
      expect(restored.reviewIntervalDays, 0);
    });

    test('dueAt が null の JSON も lastWrongAt で読める', () {
      final json = build().toJson()..['dueAt'] = null;
      expect(QuizMistakeEntry.fromJson(json).dueAt, base);
    });

    test('reviewIntervalDays が文字列なら FormatException', () {
      final json = build().toJson()..['reviewIntervalDays'] = '1';
      expect(() => QuizMistakeEntry.fromJson(json), throwsFormatException);
    });

    test('dueAt が解釈不能なら FormatException', () {
      final json = build().toJson()..['dueAt'] = 'not-a-date';
      expect(() => QuizMistakeEntry.fromJson(json), throwsFormatException);
    });
  });

  group('dueAt / reviewIntervalDays の copyWith', () {
    test('dueAt のみ更新し他は保持する', () {
      final entry = build();
      final due = base.add(const Duration(days: 1));
      final updated = entry.copyWith(dueAt: due);
      expect(updated.dueAt, due);
      expect(updated.reviewIntervalDays, 0);
      expect(updated.lastWrongAt, entry.lastWrongAt);
      expect(updated.wrongCount, entry.wrongCount);
    });

    test('reviewIntervalDays のみ更新し他は保持する', () {
      final entry = build();
      final updated = entry.copyWith(reviewIntervalDays: 14);
      expect(updated.reviewIntervalDays, 14);
      expect(updated.dueAt, entry.dueAt);
    });

    test('両方まとめて更新できる', () {
      final due = base.add(const Duration(days: 30));
      final updated = build().copyWith(dueAt: due, reviewIntervalDays: 30);
      expect(updated.dueAt, due);
      expect(updated.reviewIntervalDays, 30);
    });

    test('dueAt を誤答日時より前にすると ArgumentError', () {
      expect(
        () => build().copyWith(dueAt: base.subtract(const Duration(days: 1))),
        throwsArgumentError,
      );
    });
  });

  test('等価比較は dueAt / reviewIntervalDays も対象とする', () {
    expect(build(), build());
    expect(
      build(reviewIntervalDays: 3),
      isNot(build()),
    );
    expect(
      build(dueAt: base.add(const Duration(days: 3)), reviewIntervalDays: 3),
      isNot(build(reviewIntervalDays: 3)),
    );
  });
}
