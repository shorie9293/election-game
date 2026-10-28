import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_service.dart';

/// 起動時の自動バックアップを投げっぱなしで起動する。
///
/// 起動を妨げないこと最優先。失敗は [debugPrint] に留める。
void scheduleAutoBackup({
  required Future<String> Function() buildJson,
  AutoBackupStore? store,
  AutoBackupPolicy policy = const AutoBackupPolicy(),
  DateTime Function()? clock,
}) {
  final service = AutoBackupService(
    store: store ?? FileAutoBackupStore(),
    policy: policy,
    clock: clock,
  );
  unawaited(() async {
    try {
      final result = await service.run(buildJson);
      if (result.hasError) {
        debugPrint('[auto_backup] ⚠️ 自動バックアップ失敗（起動は継続）: ${result.error}');
      } else if (result.ran) {
        debugPrint(
          '[auto_backup] ✅ ${result.fileName} を保存（旧世代削除: ${result.pruned}件）',
        );
      }
    } catch (e) {
      debugPrint('[auto_backup] ⚠️ 自動バックアップ例外（起動は継続）: $e');
    }
  }());
}
