import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:election_game/core/crash/crash_log_entry.dart';
import 'package:election_game/core/crash/crash_log_service.dart';

/// 最後に PlatformDispatcher からゾーンへ転送したエラー（二重記録の抑止用）。
Object? _forwardedError;

/// 未捕捉例外を端末内クラッシュログへ合流させる。
///
/// - `FlutterError.onError`: 既存の設定（Crashlytics 送信 + presentError）を
///   保存し、[record] → 既存呼出 の順で合流させる。既存の挙動は変えない。
/// - `PlatformDispatcher.instance.onError`: 既存呼出を残しつつ `false` を返し、
///   ゾーン（`runZonedGuarded`）へ流して記録と抑止を委ねる。
///
/// 既存の設定を読むため、呼び出しは**既存の onError 設定より後**に行うこと。
void installCrashGuard({CrashLogger? logger}) {
  final crashLogger = logger ?? sharedCrashLogger;

  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    crashLogger.record(
      CrashLogKind.framework,
      details.exception,
      stack: details.stack,
      message: details.exceptionAsString(),
    );
    try {
      previousOnError?.call(details);
    } catch (_) {
      // 既存ハンドラ（Crashlytics 等）の失敗で記録を失わない。
    }
  };

  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    try {
      previousPlatformOnError?.call(error, stack);
    } catch (_) {
      // 既存ハンドラの失敗は無視する。
    }
    // 端末内ログは「ゾーンへ流した後」の1回だけ記録する（二重記録の回避）。
    crashLogger.record(CrashLogKind.platform, error, stack: stack);
    _forwardedError = error;
    return false;
  };
}

/// `runZonedGuarded` のハンドラ用。未捕捉例外を記録する。
///
/// [installCrashGuard] が PlatformDispatcher から転送したものは既に
/// 記録済みのため、同一インスタンスなら重ねて記録しない。
void handleZoneError(
  Object error,
  StackTrace stack, {
  CrashLogger? logger,
}) {
  if (identical(error, _forwardedError)) {
    _forwardedError = null;
    return;
  }
  (logger ?? sharedCrashLogger)
      .record(CrashLogKind.uncaught, error, stack: stack);
}

/// テスト用: 転送抑止の状態を初期化する。
@visibleForTesting
void resetCrashGuardForwardingForTest() => _forwardedError = null;
