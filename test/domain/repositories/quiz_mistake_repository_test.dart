import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';

void main() {
  final now = DateTime(2026, 10, 13, 10, 0);

  QuizMistakeEntry entry({
    String questionId = 'q1',
    int wrongCount = 1,
    int? lastSelectedIndex = 0,
    DateTime? masteredAt,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: QuizCategory.system,
      correctIndex: 1,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex,
      lastWrongAt: now,
      masteredAt: masteredAt,
    );
  }

  group('encode / decode（純粋関数）', () {
    test('往復しても等価', () {
      final entries = [
        entry(questionId: 'q1', wrongCount: 2),
        entry(questionId: 'q2', masteredAt: now.add(const Duration(hours: 1))),
      ];
      final restored = SharedPreferencesQuizMistakeRepository.decode(
        SharedPreferencesQuizMistakeRepository.encode(entries),
      );
      expect(restored, entries);
    });

    test('空リストは空文字列ではなく [] へ符号化される', () {
      expect(SharedPreferencesQuizMistakeRepository.encode(const []), '[]');
      expect(
        SharedPreferencesQuizMistakeRepository.decode('[]'),
        isEmpty,
      );
    });

    test('不正なJSONは空リストを返す', () {
      expect(
        SharedPreferencesQuizMistakeRepository.decode('{not json'),
        isEmpty,
      );
    });

    test('JSONがリストでなければ空リストを返す', () {
      expect(
        SharedPreferencesQuizMistakeRepository.decode('{"a": 1}'),
        isEmpty,
      );
    });

    test('要素単位の破損は読み飛ばし健全要素は保持する', () {
      final goodElement =
          jsonEncode(entry(questionId: 'q1').toJson());
      // 未知フィールドのみ・非マップ要素・健全要素の混在
      final raw = '[{"bogus": true}, "not-a-map", $goodElement]';
      final restored = SharedPreferencesQuizMistakeRepository.decode(raw);
      expect(restored.map((e) => e.questionId).toList(), ['q1']);
    });
  });

  group('SharedPreferencesQuizMistakeRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('保存した内容を読み戻せる', () async {
      const repo = SharedPreferencesQuizMistakeRepository();
      await repo.save([entry(questionId: 'q3', wrongCount: 4)]);

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.single.questionId, 'q3');
      expect(loaded.single.wrongCount, 4);
    });

    test('未保存なら空リストを返す', () async {
      const repo = SharedPreferencesQuizMistakeRepository();
      expect(await repo.load(), isEmpty);
    });

    test('clear で全消去される', () async {
      const repo = SharedPreferencesQuizMistakeRepository();
      await repo.save([entry()]);
      await repo.clear();
      expect(await repo.load(), isEmpty);
    });

    test('破損した保存値は空リストへフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesQuizMistakeRepository.storageKey: '{broken',
      });
      const repo = SharedPreferencesQuizMistakeRepository();
      expect(await repo.load(), isEmpty);
    });
  });

  group('InMemoryQuizMistakeRepository', () {
    test('保存・読込・消去が機能する', () async {
      final repo = InMemoryQuizMistakeRepository();
      expect(await repo.load(), isEmpty);

      await repo.save([entry(questionId: 'a')]);
      expect((await repo.load()).single.questionId, 'a');

      await repo.clear();
      expect(await repo.load(), isEmpty);
    });

    test('初期値を保持し、返却リストは外から書き換えられない', () async {
      final repo = InMemoryQuizMistakeRepository([entry(questionId: 'seed')]);
      expect(repo.entries.single.questionId, 'seed');

      final loaded = await repo.load();
      expect(() => loaded.add(entry()), throwsUnsupportedError);
    });
  });
}
