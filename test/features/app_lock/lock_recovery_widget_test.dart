import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/app_lock_gate.dart';
import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/infrastructure/lock_recovery_policy.dart';
import 'package:election_game/core/infrastructure/lock_recovery_service.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  late InMemoryAppLockRepository repo;
  late int backupCount;
  late int eraseCount;

  setUp(() {
    repo = InMemoryAppLockRepository();
    backupCount = 0;
    eraseCount = 0;
  });

  Widget buildGate() {
    final service = AppLockService(repo);
    return MaterialApp(
      home: AppLockGate(
        repository: repo,
        recoveryService: LockRecoveryService(
          service,
          backupExporter: () async => backupCount++,
          dataEraser: () async => eraseCount++,
        ),
        unlockedBuilder: (context) =>
            const Scaffold(key: AppKeys.homeTitle, body: Text('ロックされていない')),
      ),
    );
  }

  testWidgets('忘却ボタンから警告と確認入力のダイアログが開く', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.appLockForgotButton), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.appLockForgotButton));
    await tester.pumpAndSettle();

    expect(find.text(LockRecoveryPolicy.warningMessage), findsOneWidget);
    expect(find.byKey(AppKeys.appLockRecoveryConfirmField), findsOneWidget);
    expect(find.byKey(AppKeys.appLockRecoveryConfirmButton), findsOneWidget);
  });

  testWidgets('確認語が違えばエラー表示のみで解除されない', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.appLockForgotButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(AppKeys.appLockRecoveryConfirmField),
      '解除',
    );
    await tester.tap(find.byKey(AppKeys.appLockRecoveryConfirmButton));
    await tester.pumpAndSettle();

    expect(
      find.text('「${LockRecoveryPolicy.confirmationPhrase}」と入力してください'),
      findsOneWidget,
    );
    expect(find.byKey(AppKeys.appLockGateScreen), findsOneWidget);
    expect(backupCount, 0);
    expect(eraseCount, 0);
    expect(repo.isEnabled(), isTrue);
  });

  testWidgets('「初期化」入力でロック解除されデータ初期化まで走る', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.appLockForgotButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(AppKeys.appLockRecoveryConfirmField),
      LockRecoveryPolicy.confirmationPhrase,
    );
    await tester.tap(find.byKey(AppKeys.appLockRecoveryConfirmButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
    expect(find.byKey(AppKeys.appLockGateScreen), findsNothing);
    expect(find.textContaining('ロックを解除しました'), findsOneWidget);
    expect(backupCount, 1);
    expect(eraseCount, 1);
    expect(repo.isEnabled(), isFalse);
  });
}
