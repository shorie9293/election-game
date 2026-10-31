import 'dart:async';

import 'package:election_game/core/crash/crash_log_entry.dart';
import 'package:election_game/core/crash/crash_log_repository.dart';

/// クラッシュログの記録器。
///
/// [record] は投げっぱなし（戻り値なし）で、記録に失敗しても例外を外へ出さない。
/// ログの失敗がアプリの障害を増やしてはならないため。
class CrashLogger {
  CrashLogger(this.repository);

  /// 追記先。
  final CrashLogRepository repository;

  /// 1件記録する（投げっぱなし・失敗は握る）。
  void record(
    CrashLogKind kind,
    Object error, {
    StackTrace? stack,
    DateTime? timestamp,
    String? message,
  }) {
    try {
      final entry = CrashLogEntry.capture(
        kind: kind,
        error: error,
        stack: stack,
        timestamp: timestamp,
        message: message,
      );
      unawaited(_appendSafely(entry));
    } catch (_) {
      // 記録の失敗はアプリの障害ではない。
    }
  }

  /// 保存済みの全件（古い順）。
  Future<List<CrashLogEntry>> loadAll() async {
    try {
      return await repository.loadAll();
    } catch (_) {
      return const <CrashLogEntry>[];
    }
  }

  /// 全消去する（失敗は握る）。
  Future<void> clear() async {
    try {
      await repository.clear();
    } catch (_) {
      // 消せなくても致命的ではない。
    }
  }

  Future<void> _appendSafely(CrashLogEntry entry) async {
    try {
      await repository.append(entry);
    } catch (_) {
      // 記録の失敗はアプリの障害ではない。
    }
  }
}

CrashLogger? _shared;

/// アプリ全体で共有する記録器（初回参照時に端末保存の実装で生成）。
CrashLogger get sharedCrashLogger => _shared ??= CrashLogger(
      FileCrashLogRepository(),
    );

/// 共有記録器を差し替える（試練・起動時配線用）。
set sharedCrashLogger(CrashLogger logger) => _shared = logger;

/// 記録の有無を1行で要約する（0件なら null）。
///
/// 例: `前回の異常終了 2件（最終 03:04）`
///
/// 最終発生が [now] と別の日なら日付を添える（例: 11/1 03:04）。
String? summarize(List<CrashLogEntry> entries, {DateTime? now}) {
  if (entries.isEmpty) return null;
  var latest = entries.first;
  for (final entry in entries) {
    if (entry.timestamp.isAfter(latest.timestamp)) latest = entry;
  }
  final reference = now ?? DateTime.now();
  final at = latest.timestamp;
  final time =
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  final sameDay = at.year == reference.year &&
      at.month == reference.month &&
      at.day == reference.day;
  final when = sameDay ? time : '${at.month}/${at.day} $time';
  return '前回の異常終了 ${entries.length}件（最終 $when）';
}

/// 直近 [limit] 件を新しい順で返す。
List<CrashLogEntry> recent(
  List<CrashLogEntry> entries, {
  int limit = 10,
}) {
  if (limit <= 0 || entries.isEmpty) return const <CrashLogEntry>[];
  final start = entries.length <= limit ? 0 : entries.length - limit;
  return entries.sublist(start).reversed.toList();
}
