import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/crash/crash_log_entry.dart';

void main() {
  group('CrashLogEntry', () {
    test('message は先頭200文字に切り詰める', () {
      final entry = CrashLogEntry(
        timestamp: DateTime(2026, 11, 1, 12),
        kind: CrashLogKind.uncaught,
        message: 'あ' * 250,
        stackTop: '',
      );

      expect(entry.message.length, CrashLogEntry.maxMessageLength);
      expect(entry.message, 'あ' * 200);
    });

    test('stackTop は先頭10フレームに切り詰める', () {
      final stack = List<String>.generate(30, (i) => '#$i frame$i').join('\n');
      final entry = CrashLogEntry(
        timestamp: DateTime(2026, 11, 1),
        kind: CrashLogKind.framework,
        message: 'boom',
        stackTop: stack,
      );

      final lines = entry.stackTop.split('\n');
      expect(lines, hasLength(CrashLogEntry.maxStackFrames));
      expect(lines.first, '#0 frame0');
      expect(lines.last, '#9 frame9');
    });

    test('capture は StackTrace の先頭10フレームだけ残す', () {
      final stack = StackTrace.fromString(
        List<String>.generate(15, (i) => '#$i pkg.dart').join('\n'),
      );

      final entry = CrashLogEntry.capture(
        kind: CrashLogKind.platform,
        error: StateError('boom'),
        stack: stack,
        timestamp: DateTime(2026, 11, 1, 12, 34),
      );

      expect(entry.message, contains('boom'));
      expect(entry.stackTop.split('\n'), hasLength(10));
      expect(entry.timestamp, DateTime(2026, 11, 1, 12, 34));
      expect(entry.kind, CrashLogKind.platform);
    });

    test('JSON へ往復しても値が保たれる', () {
      final entry = CrashLogEntry(
        timestamp: DateTime(2026, 11, 1, 12, 34, 56, 789),
        kind: CrashLogKind.uncaught,
        message: '例外です',
        stackTop: '#0 a\n#1 b',
      );

      final restored = CrashLogEntry.fromJson(jsonEncode(entry.toJson()));

      expect(restored, entry);
      expect(restored!.timestamp, entry.timestamp);
    });

    test('壊れた入力は null（JSONでない・型違い・日時不正）', () {
      expect(CrashLogEntry.fromJson('not json'), isNull);
      expect(CrashLogEntry.fromJson('[]'), isNull);
      expect(CrashLogEntry.fromJson('{"ts":1,"kind":"framework"}'), isNull);
      expect(
        CrashLogEntry.fromJson(
          '{"ts":"2026-11-01T00:00:00.000","kind":"framework","message":1,"stackTop":""}',
        ),
        isNull,
      );
      expect(
        CrashLogEntry.fromJson(
          '{"ts":"not-a-date","kind":"framework","message":"m","stackTop":""}',
        ),
        isNull,
      );
    });

    test('未知の kind は unknown として復元する（前方互換）', () {
      final restored = CrashLogEntry.fromJson(
        '{"ts":"2026-11-01T00:00:00.000","kind":"future_kind",'
        '"message":"m","stackTop":""}',
      );

      expect(restored, isNotNull);
      expect(restored!.kind, CrashLogKind.unknown);
    });

    test('値等価: 全項目一致で等しく、1項目違えば等しくない', () {
      final a = CrashLogEntry(
        timestamp: DateTime(2026, 11, 1, 1),
        kind: CrashLogKind.framework,
        message: 'm',
        stackTop: '#0',
      );
      final b = CrashLogEntry(
        timestamp: DateTime(2026, 11, 1, 1),
        kind: CrashLogKind.framework,
        message: 'm',
        stackTop: '#0',
      );
      final c = CrashLogEntry(
        timestamp: DateTime(2026, 11, 1, 1),
        kind: CrashLogKind.platform,
        message: 'm',
        stackTop: '#0',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
