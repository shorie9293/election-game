import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';

void main() {
  late InMemoryAppLockRepository repo;
  late AppLockService service;

  setUp(() {
    repo = InMemoryAppLockRepository();
    service = AppLockService(repo);
  });

  group('AppLockService 純ロジック', () {
    test('初期状態は未ロック', () {
      expect(service.isLocked, isFalse);
    });

    test('無効時は unlock が常に true', () async {
      expect(await service.unlock(), isTrue);
      expect(await service.unlock(passcode: '0000'), isTrue);
      expect(await service.unlock(passcode: null, biometricSucceeded: false),
          isTrue);
    });

    test('enableWithPasscode で有効化され、isLocked が true', () async {
      await service.enableWithPasscode('1234');
      expect(service.isLocked, isTrue);
      expect(repo.getMethod(), AppLockMethod.passcode);
      expect(repo.getPasscodeHash(), isNotNull);
    });

    test('4桁以外は ArgumentError', () async {
      expect(
        () => service.enableWithPasscode('123'),
        throwsArgumentError,
      );
      expect(
        () => service.enableWithPasscode('12345'),
        throwsArgumentError,
      );
      expect(
        () => service.enableWithPasscode('12a4'),
        throwsArgumentError,
      );
      expect(
        () => service.enableWithPasscode('１２３４'),
        throwsArgumentError,
      );
      expect(service.isLocked, isFalse);
    });

    test('正しいパスコードで解除、誤りでは解除されない', () async {
      await service.enableWithPasscode('1234');
      expect(await service.unlock(passcode: '9999'), isFalse);
      expect(service.isLocked, isTrue);
      expect(await service.unlock(passcode: '1234'), isTrue);
    });

    test('有効だが method none の場合も素通り（整合性のため）', () async {
      await service.enableWithPasscode('1234');
      await repo.setMethod(AppLockMethod.none);
      expect(await service.unlock(passcode: '9999'), isTrue);
    });

    test('biometric 方式は委譲結果で判定', () async {
      await repo.setEnabled(true);
      await repo.setMethod(AppLockMethod.biometric);
      expect(service.isLocked, isTrue);
      expect(
          await service.unlock(passcode: null, biometricSucceeded: false),
          isFalse);
      expect(
          await service.unlock(passcode: null, biometricSucceeded: true),
          isTrue);
    });

    test('disable で全状態がクリアされる', () async {
      await service.enableWithPasscode('1234');
      await service.disable();
      expect(service.isLocked, isFalse);
      expect(repo.getMethod(), AppLockMethod.none);
      expect(repo.getPasscodeHash(), isNull);
    });
  });
}
