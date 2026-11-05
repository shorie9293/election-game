import 'dart:async';

import 'package:election_game/core/logging/app_logger.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_status_store.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_service.dart';

/// 起動時の自動バックアップを投げっぱなしで起動する。
///
/// 起動を妨げないこと最優先。失敗は [appLog] の warn に留める。
/// 成否は [statusStore] に記録し、画面が「未実行」と「毎回失敗」を
/// 区別できるようにする。
void scheduleAutoBackup({
  required Future<String> Function() buildJson,
  AutoBackupStore? store,
  AutoBackupStatusStore? statusStore,
  AutoBackupPolicy policy = const AutoBackupPolicy(),
  DateTime Function()? clock,
}) {
  final service = AutoBackupService(
    store: store ?? FileAutoBackupStore(),
    policy: policy,
    statusStore: statusStore ?? FileAutoBackupStatusStore(),
    clock: clock,
  );
  unawaited(() async {
    try {
      final result = await service.run(buildJson);
      if (result.hasError) {
        appLog.warn('[auto_backup] 自動バックアップ失敗（起動は継続）', result.error);
      } else if (result.ran) {
        appLog.info(
          '[auto_backup] ${result.fileName} を保存（旧世代削除: ${result.pruned}件）',
        );
      }
    } catch (e) {
      appLog.warn('[auto_backup] 自動バックアップ例外（起動は継続）', e);
    }
  }());
}
