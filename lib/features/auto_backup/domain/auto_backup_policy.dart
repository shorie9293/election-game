/// 自動バックアップの世代管理・実行可否を司る純粋方針。
///
/// 副作用なし・例外を投げない。現在時刻は常に呼び出し側から注入する。
library;

/// 自動バックアップ1世代分のメタ情報。
class AutoBackupEntry {
  final String fileName;
  final DateTime createdAt;

  const AutoBackupEntry({required this.fileName, required this.createdAt});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoBackupEntry &&
          other.fileName == fileName &&
          other.createdAt == createdAt;

  @override
  int get hashCode => fileName.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'AutoBackupEntry($fileName, $createdAt)';
}

/// 起動時1日1回・世代3ローテーションの自動バックアップ方針。
class AutoBackupPolicy {
  /// 既定の保持世代数。
  static const int defaultKeep = 3;

  /// 既定の実行間隔（24時間）。
  static const Duration defaultInterval = Duration(hours: 24);

  /// 自動バックアップファイル名の接頭辞。
  static const String filePrefix = 'auto_backup_';

  /// 自動バックアップファイル名の接尾辞。
  static const String fileSuffix = '.json';

  /// 実行間隔。
  final Duration interval;

  /// 保持世代数。
  final int keep;

  const AutoBackupPolicy({
    this.interval = defaultInterval,
    this.keep = defaultKeep,
  });

  /// 実行すべきか。
  ///
  /// - 直前の実行が無い（null）→ true
  /// - 前回から [interval] 以上経過 → true
  /// - 前回が未来時刻（時計巻き戻し等）→ true
  bool shouldRun({DateTime? lastAt, required DateTime now}) {
    if (lastAt == null) return true;
    if (lastAt.isAfter(now)) return true;
    return now.difference(lastAt) >= interval;
  }

  /// ローカル暦の yyyyMMdd をゼロ埋めした世代ファイル名。
  static String fileNameFor(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$filePrefix$y$m$d$fileSuffix';
  }

  /// 自動バックアップの命名規則に一致するか（手動ファイルは false）。
  static bool isAutoBackupFile(String fileName) {
    if (fileName.length <= filePrefix.length + fileSuffix.length) return false;
    return fileName.startsWith(filePrefix) && fileName.endsWith(fileSuffix);
  }

  /// 自動バックアップのうち最も新しい作成時刻。無ければ null。
  DateTime? latestCreatedAt(List<AutoBackupEntry> entries) {
    DateTime? latest;
    for (final entry in entries) {
      if (!isAutoBackupFile(entry.fileName)) continue;
      if (latest == null || entry.createdAt.isAfter(latest)) {
        latest = entry.createdAt;
      }
    }
    return latest;
  }

  /// 残す世代を返す（自動のみ・createdAt降順・同値はfileName降順・[keep]件）。
  ///
  /// 手動ファイルは返さない＝削除対象にも数えない。
  List<AutoBackupEntry> prune(List<AutoBackupEntry> entries) {
    final auto = entries
        .where((e) => isAutoBackupFile(e.fileName))
        .toList(growable: false);
    auto.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) return byTime;
      return b.fileName.compareTo(a.fileName);
    });
    if (keep <= 0) return const <AutoBackupEntry>[];
    if (auto.length <= keep) return List<AutoBackupEntry>.unmodifiable(auto);
    return List<AutoBackupEntry>.unmodifiable(auto.take(keep));
  }
}
