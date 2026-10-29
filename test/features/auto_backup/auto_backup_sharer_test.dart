import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/auto_backup/data/auto_backup_sharer_impl.dart';

void main() {
  group('TempFileAutoBackupSharer', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('auto_backup_share_test');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('内容を一時ファイルへ書き出してから共有する', () async {
      final shared = <String>[];
      final sharer = TempFileAutoBackupSharer(
        directoryResolver: () async => root,
        shareAction: (file, fileName) async {
          expect(await file.exists(), isTrue);
          expect(await file.readAsString(), '{"a":1}');
          shared.add(fileName);
        },
      );

      await sharer.share('auto_backup_20261029.json', '{"a":1}');

      expect(shared, ['auto_backup_20261029.json']);
      final written =
          File('${root.path}${Platform.pathSeparator}auto_backup_20261029.json');
      expect(await written.readAsString(), '{"a":1}');
    });

    test('ディレクトリが無ければ作成して書き出す', () async {
      final nested = Directory('${root.path}/nested/share');
      var called = 0;
      final sharer = TempFileAutoBackupSharer(
        directoryResolver: () async => nested,
        shareAction: (_, __) async => called++,
      );

      await sharer.share('auto_backup_20261029.json', '{}');

      expect(await nested.exists(), isTrue);
      expect(called, 1);
    });
  });
}
