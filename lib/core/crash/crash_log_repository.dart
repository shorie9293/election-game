import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:election_game/core/crash/crash_log_entry.dart';

/// クラッシュログの保管庫（抽象）。
///
/// 実装は失敗を握りつぶし、記録の失敗でアプリを止めないこと。
abstract class CrashLogRepository {
  /// 保存済みの全件（古い順）。
  Future<List<CrashLogEntry>> loadAll();

  /// 1件追記する。
  Future<void> append(CrashLogEntry entry);

  /// 全消去する。
  Future<void> clear();
}

/// 端末の documents/crash_log.jsonl に追記する実装。
///
/// - 1行1件の JSON Lines。壊れた行は読み飛ばす。
/// - 追記のたびに直近 [maxEntries] 件へローテートする（無制限に増やさない）。
/// - 読み書きの失敗はすべて握る（ログの失敗で起動を妨げない）。
class FileCrashLogRepository implements CrashLogRepository {
  FileCrashLogRepository({
    Future<Directory> Function()? directoryResolver,
    this.fileName = 'crash_log.jsonl',
    this.maxEntries = 50,
  }) : directoryResolver =
            directoryResolver ?? getApplicationDocumentsDirectory;

  /// documents ディレクトリの解決器（試練で差し替え可能）。
  final Future<Directory> Function() directoryResolver;

  /// 保存ファイル名。
  final String fileName;

  /// 保持する最大件数。
  final int maxEntries;

  Future<File> _file() async {
    final base = await directoryResolver();
    return File('${base.path}${Platform.pathSeparator}$fileName');
  }

  @override
  Future<List<CrashLogEntry>> loadAll() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const <CrashLogEntry>[];
      final lines = await file.readAsLines();
      final entries = <CrashLogEntry>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final entry = CrashLogEntry.fromJson(line);
        // 壊れた行（部分書き込み・形式変更）は読み飛ばして残りを活かす。
        if (entry == null) continue;
        entries.add(entry);
      }
      return entries;
    } catch (_) {
      return const <CrashLogEntry>[];
    }
  }

  @override
  Future<void> append(CrashLogEntry entry) async {
    try {
      final file = await _file();
      final entries = <CrashLogEntry>[...await loadAll(), entry];
      final kept = entries.length <= maxEntries
          ? entries
          : entries.sublist(entries.length - maxEntries);
      final buffer = StringBuffer();
      for (final item in kept) {
        buffer.writeln(jsonEncode(item.toJson()));
      }
      await file.writeAsString(buffer.toString(), flush: true);
    } catch (_) {
      // 記録できないことはアプリの障害ではない。
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 消せなくても致命的ではない。
    }
  }
}

/// 試練用・メモリ保管庫。
class InMemoryCrashLogRepository implements CrashLogRepository {
  InMemoryCrashLogRepository({
    List<CrashLogEntry>? initial,
    this.maxEntries = 50,
  }) : entries = <CrashLogEntry>[...?initial];

  /// 保存済みの記録（古い順）。
  final List<CrashLogEntry> entries;

  /// 保持する最大件数。
  final int maxEntries;

  /// 追記の呼出回数（試練の観測用）。
  int appendCalls = 0;

  @override
  Future<List<CrashLogEntry>> loadAll() async =>
      List<CrashLogEntry>.of(entries);

  @override
  Future<void> append(CrashLogEntry entry) async {
    appendCalls++;
    entries.add(entry);
    if (entries.length > maxEntries) {
      entries.removeRange(0, entries.length - maxEntries);
    }
  }

  @override
  Future<void> clear() async {
    entries.clear();
  }
}

/// 常に失敗する保管庫（握りつぶしの検証用）。
class ThrowingCrashLogRepository implements CrashLogRepository {
  @override
  Future<List<CrashLogEntry>> loadAll() async =>
      throw const FileSystemException('read failed');

  @override
  Future<void> append(CrashLogEntry entry) async =>
      throw const FileSystemException('write failed');

  @override
  Future<void> clear() async =>
      throw const FileSystemException('delete failed');
}
