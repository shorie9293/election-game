import 'package:election_game/features/backup/domain/game_data_backup.dart';

/// 一覧表示に出す上書き対象キーの既定件数。
const int kRestorePreviewSampleLimit = 5;

/// 値比較で辿る最大の入れ子段数（深すぎる入力で暴走しないための上限）。
const int _kMaxCompareDepth = 8;

/// 復元前プレビュー（内訳＋上書き対象キーの抜粋＋文言）。
///
/// バックアップ内容と現在のスナップショットから表示用の文字列を組み立てる
/// 純粋クラス。「0件の時どう言うか」という if 分岐はすべてこのクラスに
/// 閉じ込め、画面側は文字列を並べるだけにする（widget に if を散らさない）。
///
/// 破損・空・巨大な入力でも例外を投げない（表示は空内訳に落ちる）。
class RestorePreview {
  /// 新規作成されるキー数。
  final int created;

  /// 上書きされるキー数。
  final int overwritten;

  /// 変更の無いキー数。
  final int unchanged;

  /// 上書き対象キーの先頭 [kRestorePreviewSampleLimit] 件（昇順）。
  final List<String> overwriteSampleKeys;

  /// 抜粋から漏れた上書き対象キー数。
  final int hiddenOverwriteCount;

  const RestorePreview({
    required this.created,
    required this.overwritten,
    required this.unchanged,
    required this.overwriteSampleKeys,
    required this.hiddenOverwriteCount,
  });

  /// 差分の総件数（バックアップに含まれる対象キー数）。
  int get total => created + overwritten + unchanged;

  /// 書き換えが1件でも起きるか。
  bool get hasChanges => created > 0 || overwritten > 0;

  /// 要約行。例: `新規 12件 / 上書き 340件 / 変更なし 8件`
  String get summary =>
      '新規 $created件 / 上書き $overwritten件 / 変更なし $unchanged件';

  /// 上書き対象キーの抜粋。上書き0件なら null（表示しない）。
  ///
  /// 例:
  /// ```
  /// 上書きされるキー:
  /// ・election_archive
  /// ・candidate_rating_c1
  /// ほか 3件
  /// ```
  String? get samplesText {
    if (overwriteSampleKeys.isEmpty) return null;
    final buffer = StringBuffer('上書きされるキー:');
    for (final key in overwriteSampleKeys) {
      buffer.write('\n・$key');
    }
    if (hiddenOverwriteCount > 0) {
      buffer.write('\nほか $hiddenOverwriteCount件');
    }
    return buffer.toString();
  }

  /// 状況に応じた一文（境界ごとに言い回しを変える）。
  String get message {
    if (total == 0) return '復元対象のデータはありません';
    if (created == 0 && overwritten == 0) {
      return '現在のデータと一致しています。変更はありません';
    }
    if (overwritten == 0) {
      return '既存データは上書きされません（新規データのみ追加されます）';
    }
    if (created == 0) {
      return '新規データはありません。既存データが上書きされます';
    }
    return '新規データの追加と、既存データの上書きが行われます';
  }

  /// バックアップ内容（[incoming]）と現在値（[existing]）から内訳を組み立てる。
  ///
  /// - 上書き対象キーは決定的（昇順）に並べ、先頭 [sampleLimit] 件を抜粋する
  /// - [sampleLimit] が 0 以下なら抜粋なし（例外は投げない）
  /// - 値の比較で例外が起きても「上書き」に倒す（黙って無変更にしない）
  static RestorePreview build(
    Map<String, Object?> incoming,
    Map<String, Object?> existing, {
    int sampleLimit = kRestorePreviewSampleLimit,
  }) {
    var created = 0;
    var overwritten = 0;
    var unchanged = 0;
    final overwriteKeys = <String>[];

    for (final entry in incoming.entries) {
      final key = entry.key;
      if (!existing.containsKey(key)) {
        created++;
        continue;
      }
      var same = false;
      try {
        same = _sameValue(entry.value, existing[key]);
      } catch (_) {
        same = false;
      }
      if (same) {
        unchanged++;
      } else {
        overwritten++;
        overwriteKeys.add(key);
      }
    }

    overwriteKeys.sort();
    final limit = sampleLimit <= 0 ? 0 : sampleLimit;
    final sample = List<String>.unmodifiable(overwriteKeys.take(limit));
    return RestorePreview(
      created: created,
      overwritten: overwritten,
      unchanged: unchanged,
      overwriteSampleKeys: sample,
      hiddenOverwriteCount: overwriteKeys.length - sample.length,
    );
  }
}

/// JSON は `List<dynamic>`、端末保存は `List<String>` を返すため、
/// リスト・マップは中身まで見て比較する。
bool _sameValue(Object? a, Object? b, [int depth = 0]) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    if (depth >= _kMaxCompareDepth) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameValue(a[i], b[i], depth + 1)) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    if (depth >= _kMaxCompareDepth) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_sameValue(a[key], b[key], depth + 1)) return false;
    }
    return true;
  }
  return a == b;
}

/// 解析済みバックアップと現在値からプレビューを合成する薄い関数。
///
/// 画面が差分計算を直に持たずに済むようにするための入口。
RestorePreview compose({
  required GameDataBackup backup,
  required Map<String, Object?> existing,
  int sampleLimit = kRestorePreviewSampleLimit,
}) {
  return RestorePreview.build(
    backup.data,
    existing,
    sampleLimit: sampleLimit,
  );
}

/// バックアップ JSON 文字列からプレビューを合成する（表示できない時は null）。
///
/// 取得・解析の失敗はすべて null に畳む。呼び出し側は null なら
/// 従来どおりの文言だけで確認ダイアログを出す。
RestorePreview? composeFromJson(
  String? rawJson, {
  required Map<String, Object?> existing,
  GameDataBackupService service = const GameDataBackupService(),
  int sampleLimit = kRestorePreviewSampleLimit,
}) {
  if (rawJson == null) return null;
  try {
    final parsed = service.parse(rawJson);
    final backup = parsed.backup;
    if (!parsed.isSuccess || backup == null) return null;
    return compose(
      backup: backup,
      existing: existing,
      sampleLimit: sampleLimit,
    );
  } catch (_) {
    return null;
  }
}
