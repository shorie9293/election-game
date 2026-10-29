import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_presenter.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_restorer.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';

/// 現在のゲームデータをバックアップ JSON 文字列にする（既定の収集役）。
Future<String> buildCurrentGameDataJson(
  GameDataBackupRepository repository,
  DateTime now,
) async {
  final data = await repository.collect();
  return const GameDataBackupService().build(data, exportedAt: now);
}

/// 現在のゲームデータを自動バックアップとして今すぐ書き出す。
Future<void> writeAutoBackupNow({
  required AutoBackupStore store,
  required GameDataBackupRepository repository,
  required DateTime now,
}) async {
  final json = await buildCurrentGameDataJson(repository, now);
  await store.write(AutoBackupPolicy.fileNameFor(now), json);
}

/// 自動バックアップを読み、復元前に現状を強制保存してから書き戻す実装。
///
/// 例外は決して外へ投げず [AutoBackupRestoreResult] に載せる。
class StoreAutoBackupRestorer implements AutoBackupRestorer {
  /// 自動バックアップの読み書き先。
  final AutoBackupStore store;

  /// 書き戻し先（[applyBackup] 未注入時の既定経路）。
  final GameDataBackupRepository repository;

  /// 復元直前の現状を JSON 化する関数（注入必須）。
  final Future<String> Function() buildCurrentJson;

  /// 現在時刻（ローカル暦）。
  final DateTime Function() now;

  /// JSON 解釈器。
  final GameDataBackupService service;

  final Future<void> Function(Map<String, Object?> data)? _applyBackup;

  StoreAutoBackupRestorer({
    required this.store,
    required this.buildCurrentJson,
    required this.now,
    GameDataBackupRepository? repository,
    Future<void> Function(Map<String, Object?> data)? applyBackup,
    this.service = const GameDataBackupService(),
  })  : repository =
            repository ?? const SharedPreferencesGameDataBackupRepository(),
        _applyBackup = applyBackup;

  Future<void> _apply(Map<String, Object?> data) {
    final custom = _applyBackup;
    if (custom != null) return custom(data);
    return repository.restore(data, clearExisting: true);
  }

  @override
  Future<AutoBackupRestoreResult> restore(String fileName) async {
    try {
      final raw = await store.read(fileName);
      if (raw == null) {
        return const AutoBackupRestoreResult(
          ok: false,
          message: 'バックアップを読み取れませんでした（ファイルが見つかりません）',
        );
      }
      if (!AutoBackupPresenter.canRestore(raw)) {
        return const AutoBackupRestoreResult(
          ok: false,
          message: 'バックアップを読み取れませんでした（JSON形式が不正です）',
        );
      }

      final parsed = service.parse(raw);
      final backup = parsed.backup;
      if (!parsed.isSuccess || backup == null) {
        return AutoBackupRestoreResult(
          ok: false,
          message: parsed.error ?? 'バックアップの形式が不正です',
        );
      }

      // 復元前の現状を必ず退避する（復元で失うデータを救う）。
      final safetyFileName = AutoBackupPolicy.fileNameFor(now());
      final currentJson = await buildCurrentJson();
      await store.write(safetyFileName, currentJson);

      await _apply(backup.data);

      return AutoBackupRestoreResult(
        ok: true,
        message: '復元しました（$fileName）',
        safetyFileName: safetyFileName,
      );
    } catch (e) {
      return AutoBackupRestoreResult(
        ok: false,
        message: '復元できませんでした: $e',
      );
    }
  }
}
