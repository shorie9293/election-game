import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/app_lock_gate.dart';
import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/infrastructure/lock_attempt_policy.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  late InMemoryAppLockRepository repo;
  late DateTime now;

  setUp(() {
    repo = InMemoryAppLockRepository();
    now = DateTime(2026, 11, 4, 12, 0, 0);
  });

  Widget buildGate() {
    return MaterialApp(
      home: AppLockGate(
        repository: repo,
        now: () => now,
        unlockedBuilder: (_) =>
            const Scaffold(key: AppKeys.homeTitle, body: Text('ロックされていない')),
      ),
    );
  }

  Future<void> sendLifecycle(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    final data = const StringCodec().encodeMessage(state.toString());
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      data,
      (_) {},
    );
  }

  Future<void> background(WidgetTester tester) async {
    await sendLifecycle(tester, AppLifecycleState.inactive);
    await sendLifecycle(tester, AppLifecycleState.paused);
  }

  Future<void> resume(WidgetTester tester) async {
    await sendLifecycle(tester, AppLifecycleState.resumed);
    await tester.pump();
  }

  Future<void> unlockWith(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(AppKeys.appLockGateField), code);
    await tester.tap(find.byKey(AppKeys.appLockGateUnlockButton));
    await tester.pump();
  }

  testWidgets('背景化→復帰で再施錠される（既定=即時）', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await unlockWith(tester, '1234');
    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);

    await background(tester);
    now = now.add(const Duration(minutes: 3));
    await resume(tester);

    expect(find.byKey(AppKeys.appLockGateScreen), findsOneWidget);
    expect(find.byKey(AppKeys.homeTitle), findsNothing);
  });

  testWidgets('再施錠時は入力がクリアされる', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await unlockWith(tester, '1234');
    await background(tester);
    now = now.add(const Duration(seconds: 1));
    await resume(tester);

    final field = tester.widget<TextField>(
      find.byKey(AppKeys.appLockGateField),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('猶予内（1分猶予で30秒）は再施錠しない', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await repo.setRelockGraceSeconds(60);
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await unlockWith(tester, '1234');
    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);

    await background(tester);
    now = now.add(const Duration(seconds: 30));
    await resume(tester);

    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
    expect(find.byKey(AppKeys.appLockGateScreen), findsNothing);
  });

  testWidgets('猶予超過なら再施錠する（1分猶予で61秒）', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await repo.setRelockGraceSeconds(60);
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await unlockWith(tester, '1234');
    await background(tester);
    now = now.add(const Duration(seconds: 61));
    await resume(tester);

    expect(find.byKey(AppKeys.appLockGateScreen), findsOneWidget);
  });

  testWidgets('無効時は復帰してもロック画面にならない', (tester) async {
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);

    await background(tester);
    now = now.add(const Duration(minutes: 10));
    await resume(tester);

    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
    expect(find.byKey(AppKeys.appLockGateScreen), findsNothing);
  });

  testWidgets('ロックアウト中は解除ボタンが無効で案内が出る', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await repo.setFailedAttempts(LockAttemptPolicy.maxFreeAttempts);
    await repo.setLockedUntil(now.add(const Duration(seconds: 30)));

    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.appLockGateScreen), findsOneWidget);
    expect(find.byKey(AppKeys.appLockLockoutLabel), findsOneWidget);
    expect(
      find.text(LockAttemptPolicy.lockoutLabel(30)),
      findsOneWidget,
    );

    final button = tester.widget<FilledButton>(
      find.byKey(AppKeys.appLockGateUnlockButton),
    );
    expect(button.onPressed, isNull);

    // 押しても照合されず、解除されない。
    await tester.enterText(find.byKey(AppKeys.appLockGateField), '1234');
    await tester.tap(
      find.byKey(AppKeys.appLockGateUnlockButton),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.byKey(AppKeys.homeTitle), findsNothing);
    expect(repo.getFailedAttempts(), LockAttemptPolicy.maxFreeAttempts);
  });
}
