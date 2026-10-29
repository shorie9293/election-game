import 'dart:convert';

import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';

/// 自動バックアップ1行分の表示用データ。
class AutoBackupRow {
  /// 元のメタ情報。
  final AutoBackupEntry entry;

  /// UTF-8 のバイト長。
  final int byteSize;

  /// 新しい順の世代番号（1始まり）。
  final int generation;

  /// 復元可能な JSON か。
  final bool restorable;

  /// 'yyyy-MM-dd HH:mm'（ローカル暦）。
  final String dateLabel;

  /// '512 B' / '12.4 KB' など。
  final String sizeLabel;

  /// '2026-10-29 07:12 / 12.4 KB / 第1世代'。
  final String displayLabel;

  const AutoBackupRow({
    required this.entry,
    required this.byteSize,
    required this.generation,
    required this.restorable,
    required this.dateLabel,
    required this.sizeLabel,
    required this.displayLabel,
  });

  @override
  String toString() => 'AutoBackupRow($displayLabel)';
}

/// 自動バックアップ一覧の表示整形（純粋・例外を投げない）。
class AutoBackupPresenter {
  /// 保持世代数（[retentionLabel] に使う）。
  final int keep;

  const AutoBackupPresenter({this.keep = AutoBackupPolicy.defaultKeep});

  /// ローカル暦の 'yyyy-MM-dd HH:mm'。UTC 変換はしない（JST赤化防止）。
  static String formatDate(DateTime at) {
    final y = at.year.toString().padLeft(4, '0');
    final mo = at.month.toString().padLeft(2, '0');
    final d = at.day.toString().padLeft(2, '0');
    final h = at.hour.toString().padLeft(2, '0');
    final mi = at.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  /// 1024 基数・小数1桁のサイズ表記。
  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 復元可能か（トップが JSON オブジェクトのみ true）。
  static bool canRestore(String? contents) {
    if (contents == null) return false;
    if (contents.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(contents);
      return decoded is Map;
    } catch (_) {
      return false;
    }
  }

  /// createdAt 降順→fileName 降順。元リストは変更しない。
  static List<AutoBackupEntry> sortNewestFirst(List<AutoBackupEntry> entries) {
    final sorted = List<AutoBackupEntry>.of(entries);
    sorted.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) return byTime;
      return b.fileName.compareTo(a.fileName);
    });
    return sorted;
  }

  /// 自動ファイルのみ・新しい順・世代1始まりの表示行を作る。
  List<AutoBackupRow> buildRows({
    required List<AutoBackupEntry> entries,
    required Map<String, String?> contents,
  }) {
    final auto = entries
        .where((e) => AutoBackupPolicy.isAutoBackupFile(e.fileName))
        .toList(growable: false);
    final sorted = sortNewestFirst(auto);

    final rows = <AutoBackupRow>[];
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final content = contents[entry.fileName];
      final byteSize = content == null ? 0 : utf8.encode(content).length;
      final dateLabel = formatDate(entry.createdAt);
      final sizeLabel = formatSize(byteSize);
      final generation = i + 1;
      rows.add(
        AutoBackupRow(
          entry: entry,
          byteSize: byteSize,
          generation: generation,
          restorable: canRestore(content),
          dateLabel: dateLabel,
          sizeLabel: sizeLabel,
          displayLabel: '$dateLabel / $sizeLabel / 第$generation世代',
        ),
      );
    }
    return rows;
  }

  /// '保持 3世代中 2件'。
  String retentionLabel(int count) => '保持 $keep世代中 $count件';
}
