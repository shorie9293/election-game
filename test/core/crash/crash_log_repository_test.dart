import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/crash/crash_log_entry.dart';
import 'package:election_game/core/crash/crash_log_repository.dart';

CrashLogEntry _entry(int index, {DateTime? at}) => CrashLogEntry(
      timestamp: at ?? DateTime(2026, 11, 1, 0, index % 60),
      kind: CrashLogKind.uncaught,
      message: 'error-$index',
      stackTop: '#0 frame$index',
    );

void main() {
  group('FileCrashLogRepository', () {
    late Directory dir;
    late FileCrashLogRepository repository;
    late File file;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('crash_log_test');
      file = File('${dir.path}${Platform.pathSeparator}crash_log.jsonl');
      repository = FileCrashLogRepository(
        directoryResolver: () async => dir,
      );
    });

    tearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('record 相当の append で1行増える', () async {
      await repository.append(_entry(1));

      final lines = await file.readAsLines();
      expect(lines, hasLength(1));
      final entries = await repository.loadAll();
      expect(entries, hasLength(1));
      expect(entries.single.message, 'error-1');
    });

    test('51件目で最古が落ちて50件になる（直近50件ローテート）', () async {
      for (var i = 0; i < 51; i++) {
        await repository.append(_entry(i));
      }

      final entries = await repository.loadAll();
      expect(entries, hasLength(50));
      expect(entries.first.message, 'error-1');
      expect(entries.last.message, 'error-50');
      expect(await file.readAsLines(), hasLength(50));
    });

    test('壊れた行は読み飛ばし、残りの記録は活かす', () async {
      await repository.append(_entry(1));
      await file.writeAsString(
        '{"ts":"broken"}\nnot json at all\n\n',
        mode: FileMode.append,
      );
      await repository.append(_entry(2));

      final entries = await repository.loadAll();
      expect(entries, hasLength(2));
      expect(entries.map((e) => e.message), ['error-1', 'error-2']);
    });

    test('存在しないファイルは空（例外を投げない）', () async {
      expect(await repository.loadAll(), isEmpty);
    });

    test('ディレクトリ解決が失敗しても握る（空・追記も例外なし）', () async {
      final failing = FileCrashLogRepository(
        directoryResolver: () async =>
            throw const FileSystemException('no dir'),
      );

      expect(await failing.loadAll(), isEmpty);
      await failing.append(_entry(1)); // 例外が外へ出ないこと
      await failing.clear();
    });

    test('clear で全消去する', () async {
      await repository.append(_entry(1));
      await repository.clear();

      expect(await file.exists(), isFalse);
      expect(await repository.loadAll(), isEmpty);
    });
  });

  group('InMemoryCrashLogRepository', () {
    test('append は古い順に積み、上限で最古を落とす', () async {
      final repository = InMemoryCrashLogRepository(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        await repository.append(_entry(i));
      }

      final entries = await repository.loadAll();
      expect(entries.map((e) => e.message), ['error-2', 'error-3', 'error-4']);
      expect(repository.appendCalls, 5);
    });

    test('clear で空になる', () async {
      final repository = InMemoryCrashLogRepository(initial: [_entry(0)])
        ..appendCalls = 0;
      await repository.clear();

      expect(await repository.loadAll(), isEmpty);
    });
  });

  group('ThrowingCrashLogRepository', () {
    test('常に失敗する実装（握りつぶしの検証用）', () async {
      final repository = ThrowingCrashLogRepository();

      await expectLater(
          repository.loadAll(), throwsA(isA<FileSystemException>()));
      await expectLater(
          repository.append(_entry(0)), throwsA(isA<FileSystemException>()));
      await expectLater(
          repository.clear(), throwsA(isA<FileSystemException>()));
    });
  });
}
