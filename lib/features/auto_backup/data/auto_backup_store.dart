import 'dart:io';

import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:path_provider/path_provider.dart';

/// 自動バックアップの保存先抽象。
abstract class AutoBackupStore {
  /// 自動バックアップのみを列挙する（手動ファイルは含めない）。
  Future<List<AutoBackupEntry>> list();

  /// [fileName] の内容を読む（存在しなければ null）。
  Future<String?> read(String fileName);

  /// [fileName] へ [contents] を書き出す（上書き）。
  Future<void> write(String fileName, String contents);

  /// [fileName] を削除する（存在しなくても失敗しない）。
  Future<void> delete(String fileName);
}

/// 試練用のメモリ保管庫。
class InMemoryAutoBackupStore implements AutoBackupStore {
  /// fileName → 内容。
  final Map<String, String> contents = <String, String>{};

  /// fileName → 作成時刻（未指定なら書き込み時刻）。
  final Map<String, DateTime> createdAt = <String, DateTime>{};

  DateTime Function() clock;

  InMemoryAutoBackupStore({DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  @override
  Future<List<AutoBackupEntry>> list() async {
    final names = contents.keys.toList()..sort();
    return [
      for (final name in names)
        AutoBackupEntry(
          fileName: name,
          createdAt: createdAt[name] ?? clock(),
        ),
    ];
  }

  @override
  Future<String?> read(String fileName) async => contents[fileName];

  @override
  Future<void> write(String fileName, String contents) async {
    this.contents[fileName] = contents;
    createdAt.putIfAbsent(fileName, clock);
  }

  @override
  Future<void> delete(String fileName) async {
    contents.remove(fileName);
    createdAt.remove(fileName);
  }
}

/// 端末の documents/auto_backups に保存する実装。
class FileAutoBackupStore implements AutoBackupStore {
  /// documents ディレクトリの解決器（試練で差し替え可能）。
  final Future<Directory> Function() directoryResolver;

  /// documents 配下のサブディレクトリ名。
  final String subdirectory;

  FileAutoBackupStore({
    Future<Directory> Function()? directoryResolver,
    this.subdirectory = 'auto_backups',
  }) : directoryResolver = directoryResolver ?? getApplicationDocumentsDirectory;

  Future<Directory> _resolve() async {
    final base = await directoryResolver();
    final dir = Directory('${base.path}${Platform.pathSeparator}$subdirectory');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<List<AutoBackupEntry>> list() async {
    final dir = await _resolve();
    if (!await dir.exists()) return const <AutoBackupEntry>[];
    final entries = <AutoBackupEntry>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? entity.path
          : entity.uri.pathSegments.last;
      if (!AutoBackupPolicy.isAutoBackupFile(name)) continue;
      DateTime createdAt;
      try {
        createdAt = (await entity.stat()).modified;
      } catch (_) {
        continue; // 読めないファイルは世代管理の対象外
      }
      entries.add(AutoBackupEntry(fileName: name, createdAt: createdAt));
    }
    return entries;
  }

  @override
  Future<String?> read(String fileName) async {
    try {
      final dir = await _resolve();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String fileName, String contents) async {
    final dir = await _resolve();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(contents, flush: true);
  }

  @override
  Future<void> delete(String fileName) async {
    final dir = await _resolve();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
