/// 自動バックアップ復元の結果。
class AutoBackupRestoreResult {
  /// 復元できたか。
  final bool ok;

  /// 利用者に見せる日本語メッセージ。
  final String message;

  /// 復元前に現状を退避したファイル名（未実施なら null）。
  final String? safetyFileName;

  const AutoBackupRestoreResult({
    required this.ok,
    required this.message,
    this.safetyFileName,
  });

  @override
  String toString() =>
      'AutoBackupRestoreResult(ok: $ok, message: $message, safety: $safetyFileName)';
}

/// 自動バックアップ1件をゲームデータへ書き戻す抽象。
abstract interface class AutoBackupRestorer {
  /// [fileName] を復元する。例外を外へ投げない。
  Future<AutoBackupRestoreResult> restore(String fileName);
}
