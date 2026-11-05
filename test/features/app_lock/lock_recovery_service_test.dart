import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/infrastructure/lock_recovery_policy.dart';
import 'package:election_game/core/infrastructure/lock_recovery_service.dart';

/// disable() が必ず失敗するサービス（fail-safe 検証用）。
class _ThrowingDisableService extends AppLockService {
  _ThrowingDisableService(super.repository);

  @override
  Future<void> disable() async => throw StateError('disable failed');
}

void main() {
  late InMemoryAppLockRepository repo;
  late List<String> calls;

  setUp(() {
    repo = InMemoryAppLockRepository();
    calls = <String>[];
  });

  LockRecoveryService build({
    AppLockService? service,
    Future<void> Function()? backup,
    Future<void> Function()? erase,
  }) {
    return LockRecoveryService(
      service ?? AppLockService(repo),
      backupExporter: backup ??
          () async {
            calls.add('backup');
          },
      dataEraser: erase ??
          () async {
            calls.add('erase');
          },
    );
  }

  test('ロック無効なら rejected で何もしない', () async {
    final result = await build().recover(
      confirmation: LockRecoveryPolicy.confirmationPhrase,
    );

    expect(result.accepted, isFalse);
    expect(calls, isEmpty);
  });

  test('確認語が違えば rejected で状態は変わらない', () async {
    await AppLockService(repo).enableWithPasscode('1234');

    final result = await build().recover(confirmation: '解除');

    expect(result.accepted, isFalse);
    expect(calls, isEmpty);
    expect(repo.isEnabled(), isTrue);
  });

  test('受付時は バックアップ → 解除 → 初期化 の順で実行する', () async {
    await AppLockService(repo).enableWithPasscode('1234');
    final service = build(
      backup: () async {
        calls.add('backup');
        expect(repo.isEnabled(), isTrue); // バックアップ時点ではまだロック中
      },
      erase: () async {
        calls.add('erase');
        expect(repo.isEnabled(), isFalse); // 解除後に初期化する
      },
    );

    final result = await service.recover(
      confirmation: LockRecoveryPolicy.confirmationPhrase,
    );

    expect(calls, ['backup', 'erase']);
    expect(result.accepted, isTrue);
    expect(result.backupFailed, isFalse);
    expect(result.dataWiped, isTrue);
    expect(repo.isEnabled(), isFalse);
    expect(repo.getPasscodeHash(), isNull);
  });

  test('バックアップ失敗でも解除と初期化は続行する', () async {
    await AppLockService(repo).enableWithPasscode('1234');
    final service = build(
      backup: () async => throw StateError('backup failed'),
    );

    final result = await service.recover(
      confirmation: LockRecoveryPolicy.confirmationPhrase,
    );

    expect(result.accepted, isTrue);
    expect(result.backupFailed, isTrue);
    expect(result.dataWiped, isTrue);
    expect(calls, ['erase']);
    expect(repo.isEnabled(), isFalse);
  });

  test('初期化失敗でもロック解除は維持される（fail-safe）', () async {
    await AppLockService(repo).enableWithPasscode('1234');
    final service = build(
      erase: () async => throw StateError('erase failed'),
    );

    final result = await service.recover(
      confirmation: LockRecoveryPolicy.confirmationPhrase,
    );

    expect(result.accepted, isTrue);
    expect(result.dataWiped, isFalse);
    expect(repo.isEnabled(), isFalse);
  });

  test('解除が例外でも例外を外へ出さず、初期化は実行しない', () async {
    await AppLockService(repo).enableWithPasscode('1234');
    final service = build(service: _ThrowingDisableService(repo));

    final result = await service.recover(
      confirmation: LockRecoveryPolicy.confirmationPhrase,
    );

    expect(result.accepted, isTrue);
    expect(result.dataWiped, isFalse);
    expect(calls, ['backup']);
  });
}
