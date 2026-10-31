import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/crash/crash_guard.dart';
import 'package:election_game/core/crash/crash_log_entry.dart';
import 'package:election_game/core/crash/crash_log_repository.dart';
import 'package:election_game/core/crash/crash_log_service.dart';

void main() {
  late InMemoryCrashLogRepository repository;
  late CrashLogger logger;
  late FlutterExceptionHandler? savedOnError;
  late bool Function(Object, StackTrace)? savedPlatformOnError;

  setUp(() {
    repository = InMemoryCrashLogRepository();
    logger = CrashLogger(repository);
    savedOnError = FlutterError.onError;
    savedPlatformOnError = PlatformDispatcher.instance.onError;
    resetCrashGuardForwardingForTest();
  });

  tearDown(() {
    FlutterError.onError = savedOnError;
    PlatformDispatcher.instance.onError = savedPlatformOnError;
    resetCrashGuardForwardingForTest();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('installCrashGuard', () {
    test('既存の FlutterError.onError を呼びつつ端末ログにも残す', () async {
      var existingCalls = 0;
      FlutterError.onError = (details) => existingCalls++;

      installCrashGuard(logger: logger);
      FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('フレーム内の禍津')),
      );
      await settle();

      expect(existingCalls, 1, reason: '既存の挙動は変えない');
      expect(repository.entries, hasLength(1));
      expect(repository.entries.single.kind, CrashLogKind.framework);
      expect(repository.entries.single.message, contains('フレーム内の禍津'));
    });

    test('既存ハンドラが例外を投げても記録は失わない', () async {
      FlutterError.onError = (details) => throw StateError('既存側の失敗');

      installCrashGuard(logger: logger);
      expect(
        () => FlutterError.reportError(
          FlutterErrorDetails(exception: StateError('本体')),
        ),
        returnsNormally,
      );
      await settle();

      expect(repository.entries, hasLength(1));
    });

    test('PlatformDispatcher.onError は false を返してゾーンへ流す', () async {
      installCrashGuard(logger: logger);
      final handler = PlatformDispatcher.instance.onError!;

      final handled = handler(StateError('非同期の禍津'), StackTrace.current);
      await settle();

      expect(handled, isFalse);
      expect(repository.entries, hasLength(1));
      expect(repository.entries.single.kind, CrashLogKind.platform);
    });

    test('既存の PlatformDispatcher.onError も呼ばれる', () async {
      var existingCalls = 0;
      PlatformDispatcher.instance.onError = (error, stack) {
        existingCalls++;
        return true;
      };

      installCrashGuard(logger: logger);
      PlatformDispatcher.instance.onError!(
        StateError('二重に拾う'),
        StackTrace.current,
      );
      await settle();

      expect(existingCalls, 1);
    });
  });

  group('handleZoneError', () {
    test('未捕捉例外を1件記録する', () async {
      handleZoneError(StateError('ゾーンの禍津'), StackTrace.current, logger: logger);
      await settle();

      expect(repository.entries, hasLength(1));
      expect(repository.entries.single.kind, CrashLogKind.uncaught);
    });

    test('PlatformDispatcher から転送された同一例外は二重記録しない', () async {
      installCrashGuard(logger: logger);
      final error = StateError('転送される禍津');

      PlatformDispatcher.instance.onError!(error, StackTrace.current);
      await settle();
      handleZoneError(error, StackTrace.current, logger: logger);
      await settle();

      expect(repository.entries, hasLength(1));
      expect(repository.entries.single.kind, CrashLogKind.platform);
    });
  });
}
