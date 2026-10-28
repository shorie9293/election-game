import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';

/// 自動バックアップ1回分の結果。
class AutoBackupResult {
  /// 実際に書き出したか。
  final bool ran;

  /// 書き出したファイル名（未実行なら null）。
  final String? fileName;

  /// 削除した旧世代数。
  final int pruned;

  /// 失敗時のメッセージ（成功・未実行なら null）。
  final String? error;

  const AutoBackupResult({
    this.ran = false,
    this.fileName,
    this.pruned = 0,
    this.error,
  });

  bool get hasError => error != null;

  @override
  String toString() =>
      'AutoBackupResult(ran: $ran, fileName: $fileName, pruned: $pruned, error: $error)';
}

/// 起動時自動バックアップの実行役（全例外を握る）。
class AutoBackupService {
  final AutoBackupStore store;
  final AutoBackupPolicy policy;
  final DateTime Function() clock;

  AutoBackupService({
    required this.store,
    AutoBackupPolicy? policy,
    DateTime Function()? clock,
  })  : policy = policy ?? const AutoBackupPolicy(),
        clock = clock ?? DateTime.now;

  /// list → latest → shouldRun → build → write → list → prune → delete。
  ///
  /// 例外は決して外へ投げず [AutoBackupResult.error] に載せる。
  /// 24時間以内の再起動では何もせず ran=false を返す（同日冪等）。
  Future<AutoBackupResult> run(Future<String> Function() buildJson) async {
    final now = clock();
    try {
      final entries = await store.list();
      final latest = policy.latestCreatedAt(entries);
      if (!policy.shouldRun(lastAt: latest, now: now)) {
        return const AutoBackupResult();
      }

      final fileName = AutoBackupPolicy.fileNameFor(now);
      final json = await buildJson();
      await store.write(fileName, json);

      final after = await store.list();
      final kept = policy.prune(after);
      final keptNames = {for (final entry in kept) entry.fileName};

      var pruned = 0;
      for (final entry in after) {
        if (!AutoBackupPolicy.isAutoBackupFile(entry.fileName)) continue;
        if (keptNames.contains(entry.fileName)) continue;
        try {
          await store.delete(entry.fileName);
          pruned++;
        } catch (_) {
          // 1件の削除失敗で全体を止めない
        }
      }

      return AutoBackupResult(ran: true, fileName: fileName, pruned: pruned);
    } catch (e) {
      return AutoBackupResult(error: e.toString());
    }
  }
}
