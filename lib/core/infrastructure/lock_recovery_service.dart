import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/infrastructure/lock_recovery_policy.dart';

/// 回復前にバックアップを書き出す処理（失敗は例外で知らせる）。
typedef LockRecoveryBackupExporter = Future<void> Function();

/// ゲームデータを初期化する処理（失敗は例外で知らせる）。
typedef LockRecoveryDataEraser = Future<void> Function();

/// 回復1回分の結果。
class LockRecoveryResult {
  /// 回復を受け付けて実行したか（false なら何も変更していない）。
  final bool accepted;

  /// バックアップ書き出しに失敗したか。
  final bool backupFailed;

  /// データ初期化まで到達したか。
  final bool dataWiped;

  const LockRecoveryResult({
    required this.accepted,
    this.backupFailed = false,
    this.dataWiped = false,
  });

  /// 前提を満たさず何もしなかった場合。
  const LockRecoveryResult.rejected()
      : accepted = false,
        backupFailed = false,
        dataWiped = false;

  @override
  String toString() =>
      'LockRecoveryResult(accepted: $accepted, backupFailed: $backupFailed, '
      'dataWiped: $dataWiped)';
}

/// パスコード忘却時の回復役。
///
/// 順序は固定: バックアップ書き出し試行 → ロック解除 → データ初期化。
/// 初期化が失敗してもロック解除は取り消さない（fail-safe）。
/// いかなる例外も呼び出し側へは投げない。
class LockRecoveryService {
  final AppLockService _appLock;
  final LockRecoveryBackupExporter _backupExporter;
  final LockRecoveryDataEraser _dataEraser;

  LockRecoveryService(
    this._appLock, {
    required LockRecoveryBackupExporter backupExporter,
    required LockRecoveryDataEraser dataEraser,
  })  : _backupExporter = backupExporter,
        _dataEraser = dataEraser;

  /// 回復を実行する。
  ///
  /// ロックが無効、または確認語が一致しない場合は [LockRecoveryResult.rejected]
  /// を返し、状態を一切変更しない。
  Future<LockRecoveryResult> recover({required String confirmation}) async {
    if (!LockRecoveryPolicy.canRecover(enabled: _appLock.isLocked)) {
      return const LockRecoveryResult.rejected();
    }
    if (!LockRecoveryPolicy.isConfirmationValid(confirmation)) {
      return const LockRecoveryResult.rejected();
    }

    var backupFailed = false;
    try {
      await _backupExporter();
    } catch (_) {
      backupFailed = true;
    }

    // ロック解除は必ず試みる（ここで例外が出ても初期化へ進む）。
    var lockReleased = true;
    try {
      await _appLock.disable();
    } catch (_) {
      lockReleased = false;
    }

    var dataWiped = false;
    if (lockReleased) {
      try {
        await _dataEraser();
        dataWiped = true;
      } catch (_) {
        dataWiped = false;
      }
    }

    return LockRecoveryResult(
      accepted: true,
      backupFailed: backupFailed,
      dataWiped: dataWiped,
    );
  }
}
