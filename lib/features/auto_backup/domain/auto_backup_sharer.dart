/// 自動バックアップ1件を端末外へ共有する抽象。
abstract interface class AutoBackupSharer {
  /// [json] を [fileName] として共有する。失敗時は例外を投げてよい。
  Future<void> share(String fileName, String json);
}
