import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/crash/crash_log_entry.dart';
import 'package:election_game/core/crash/crash_log_repository.dart';
import 'package:election_game/core/crash/crash_log_service.dart';

CrashLogEntry _entry(DateTime at, {String message = 'm'}) => CrashLogEntry(
      timestamp: at,
      kind: CrashLogKind.uncaught,
      message: message,
      stackTop: '#0',
    );

void main() {
  group('CrashLogger.record', () {
    test('1件記録すると保管庫が1行増える', () async {
      final repository = InMemoryCrashLogRepository();
      final logger = CrashLogger(repository);

      logger.record(
        CrashLogKind.framework,
        StateError('boom'),
        stack: StackTrace.current,
        timestamp: DateTime(2026, 11, 1, 12, 34),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.entries, hasLength(1));
      final entry = repository.entries.single;
      expect(entry.kind, CrashLogKind.framework);
      expect(entry.message, contains('boom'));
      expect(entry.timestamp, DateTime(2026, 11, 1, 12, 34));
    });

    test('保管庫が失敗しても例外を外へ出さない（投げっぱなし）', () async {
      final logger = CrashLogger(ThrowingCrashLogRepository());

      expect(
        () => logger.record(CrashLogKind.uncaught, StateError('boom')),
        returnsNormally,
      );
      // 非同期側の失敗も握られること。
      await Future<void>.delayed(Duration.zero);
    });

    test('loadAll は失敗時に空を返す', () async {
      final logger = CrashLogger(ThrowingCrashLogRepository());

      expect(await logger.loadAll(), isEmpty);
    });

    test('message 引数が例外文言より優先される', () async {
      final repository = InMemoryCrashLogRepository();
      final logger = CrashLogger(repository);

      logger.record(
        CrashLogKind.framework,
        StateError('raw'),
        message: '整形済みの文言',
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.entries.single.message, '整形済みの文言');
    });
  });

  group('summarize', () {
    final now = DateTime(2026, 11, 1, 15, 0);

    test('0件なら null', () {
      expect(summarize(const [], now: now), isNull);
    });

    test('2件なら「前回の異常終了 2件（最終 HH:mm）」', () {
      final entries = [
        _entry(DateTime(2026, 11, 1, 3, 4)),
        _entry(DateTime(2026, 11, 1, 9, 30)),
      ];

      expect(
        summarize(entries, now: now),
        '前回の異常終了 2件（最終 09:30）',
      );
    });

    test('最終発生が別の日なら日付を添える', () {
      final entries = [_entry(DateTime(2026, 10, 30, 23, 5))];

      expect(
        summarize(entries, now: now),
        '前回の異常終了 1件（最終 10/30 23:05）',
      );
    });

    test('並び順に依らず最新時刻を「最終」に使う', () {
      final entries = [
        _entry(DateTime(2026, 11, 1, 9, 30)),
        _entry(DateTime(2026, 11, 1, 3, 4)),
      ];

      expect(summarize(entries, now: now), contains('最終 09:30'));
    });
  });

  group('recent', () {
    test('新しい順に limit 件だけ返す', () {
      final entries = [
        for (var i = 1; i <= 5; i++) _entry(DateTime(2026, 11, 1, i))
      ];

      final rows = recent(entries, limit: 2);

      expect(rows, hasLength(2));
      expect(rows.first.timestamp.hour, 5);
      expect(rows.last.timestamp.hour, 4);
    });

    test('件数が limit 以下なら全部を新しい順で返す', () {
      final entries = [
        _entry(DateTime(2026, 11, 1, 1)),
        _entry(DateTime(2026, 11, 1, 2)),
      ];

      expect(recent(entries, limit: 10).map((e) => e.timestamp.hour), [2, 1]);
    });

    test('空・limit 0 は空', () {
      expect(recent(const [], limit: 5), isEmpty);
      expect(recent([_entry(DateTime(2026, 11, 1))], limit: 0), isEmpty);
    });
  });
}
