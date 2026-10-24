import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/crossapp/domain/election_reward_event.dart';

void main() {
  group('election_reward_event builders', () {
    test('formatTimestamp は UTC の ISO8601 を返す', () {
      expect(
        formatTimestamp(DateTime.utc(2026, 1, 2, 3, 4, 5)),
        '2026-01-02T03:04:05.000Z',
      );
    });

    test('formatTimestamp はローカル時刻を UTC へ正規化する（瞬間は不変）', () {
      final local = DateTime(2026, 1, 2, 3, 4, 5);
      final parsed = DateTime.parse(formatTimestamp(local));
      expect(parsed.isUtc, isTrue);
      expect(parsed.isAtSameMomentAs(local), isTrue);
    });

    test('normalizeVoteShare は 0..100 にクランプする', () {
      expect(normalizeVoteShare(-5), 0);
      expect(normalizeVoteShare(0), 0);
      expect(normalizeVoteShare(42), 42);
      expect(normalizeVoteShare(100), 100);
      expect(normalizeVoteShare(151), 100);
    });

    test('voteSharePercent は当選者の得票率を四捨五入で返す', () {
      expect(
        voteSharePercent({'a': 3, 'b': 1}, 'a'),
        75,
      );
      // 総得票0・勝者不明は 0
      expect(voteSharePercent({'a': 0, 'b': 0}, 'a'), 0);
      expect(voteSharePercent(null, 'a'), 0);
      expect(voteSharePercent({'a': 1}, null), 0);
      // 負値の票は 0 として数え、結果は 0..100 に収まる
      expect(voteSharePercent({'a': 2, 'b': -3}, 'a'), 100);
    });

    test('generateEventId は 32桁の hex を生成し、毎回異なる', () {
      final a = generateEventId();
      final b = generateEventId();
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(a, isNot(b));
    });

    test('buildElectionCompletedEvent は凍結契約 v1 のスキーマを満たす', () {
      final event = buildElectionCompletedEvent(
        userId: 'abcd1234-5678-90ab-cdef-1234567890ab',
        wins: 2,
        won: true,
        voteShare: 62,
        scale: '天照町',
        electionId: 'election_1',
        clock: () => DateTime.utc(2026, 5, 6, 7, 8, 9),
        eventIdGenerator: () => 'fixed-event-id',
      );

      expect(event['event_id'], 'fixed-event-id');
      expect(event['event_type'], 'election_completed');
      expect(event['user_id'], 'abcd1234-5678-90ab-cdef-1234567890ab');
      expect(event['timestamp'], '2026-05-06T07:08:09.000Z');

      final metadata = event['metadata'] as Map<String, dynamic>;
      expect(metadata, {
        'wins': 2,
        'won': true,
        'vote_share': 62,
        'scale': '天照町',
        'election_id': 'election_1',
      });
    });

    test('buildElectionCompletedEvent は負値を 0 にクランプする', () {
      final event = buildElectionCompletedEvent(
        userId: 'u',
        wins: -3,
        won: false,
        voteShare: -20,
        scale: '天照村',
        electionId: 'e',
        eventIdGenerator: () => 'id',
      );
      final metadata = event['metadata'] as Map<String, dynamic>;
      expect(metadata['wins'], 0);
      expect(metadata['vote_share'], 0);
      expect(metadata['won'], isFalse);
    });

    test('buildQuizCompletedEvent は凍結契約 v1 のスキーマを満たす', () {
      final event = buildQuizCompletedEvent(
        userId: 'abcd1234',
        correctCount: 3,
        total: 5,
        passed: false,
        clock: () => DateTime.utc(2026, 5, 6, 7, 8, 9),
        eventIdGenerator: () => 'quiz-id',
      );

      expect(event['event_id'], 'quiz-id');
      expect(event['event_type'], 'quiz_completed');
      expect(event['user_id'], 'abcd1234');
      expect(event['timestamp'], '2026-05-06T07:08:09.000Z');
      expect(event['metadata'], {
        'correct_count': 3,
        'total': 5,
        'passed': false,
      });
    });

    test('buildQuizCompletedEvent は負値を 0 にクランプする', () {
      final event = buildQuizCompletedEvent(
        userId: 'u',
        correctCount: -1,
        total: -9,
        passed: false,
        eventIdGenerator: () => 'id',
      );
      final metadata = event['metadata'] as Map<String, dynamic>;
      expect(metadata['correct_count'], 0);
      expect(metadata['total'], 0);
    });

    test('encodeEventLine は1行のコンパクトJSONを返し、往復で一致する', () {
      final event = buildElectionCompletedEvent(
        userId: 'abcd1234',
        wins: 1,
        won: true,
        voteShare: 55,
        scale: '天照市',
        electionId: 'e-1',
        clock: () => DateTime.utc(2026, 5, 6),
        eventIdGenerator: () => 'id-1',
      );

      final line = encodeEventLine(event);

      expect(line.contains('\n'), isFalse, reason: '1イベント1行・改行禁止');
      expect(line.contains('\r'), isFalse);
      expect(jsonDecode(line), event);
    });

    test('encodeEventLine は文字列中の改行をエスケープし行を割らない', () {
      final line = encodeEventLine({
        'event_id': 'id',
        'note': '一行目\n二行目',
      });
      expect(line.contains('\n'), isFalse);
      expect((jsonDecode(line) as Map<String, dynamic>)['note'], '一行目\n二行目');
    });
  });

  group('link code helpers', () {
    test('normalizeLinkCode は前後の空白を落とす', () {
      expect(normalizeLinkCode('  abcd1234  '), 'abcd1234');
      expect(normalizeLinkCode('\tabcd1234\n'), 'abcd1234');
    });

    test('exportUserIdFrom は先頭8文字を返す（rpg-task の照合単位）', () {
      expect(
        exportUserIdFrom('abcd1234-5678-90ab-cdef-1234567890ab'),
        'abcd1234',
      );
      expect(exportUserIdFrom('  abcd1234  '), 'abcd1234');
    });

    test('exportUserIdFrom は8文字未満・空なら空文字（書き出し抑止）', () {
      expect(exportUserIdFrom(''), '');
      expect(exportUserIdFrom('   '), '');
      expect(exportUserIdFrom('abc'), '');
    });
  });
}
