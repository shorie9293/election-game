import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/app_lock_gate.dart';
import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  late InMemoryAppLockRepository repo;

  setUp(() {
    repo = InMemoryAppLockRepository();
  });

  Widget buildGate() {
    return MaterialApp(
      home: AppLockGate(
        repository: repo,
        unlockedBuilder: (context) =>
            const Scaffold(key: AppKeys.homeTitle, body: Text('ロックされていない')),
      ),
    );
  }

  testWidgets('無効時は子が表示される（素通り）', (tester) async {
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
    expect(find.byKey(AppKeys.appLockGateScreen), findsNothing);
  });

  testWidgets('有効時は子が隠れ、ロック画面が表示される', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.appLockGateScreen), findsOneWidget);
    expect(find.byKey(AppKeys.homeTitle), findsNothing);
  });

  testWidgets('有効時、誤コードでエラー表示・解除されない', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppKeys.appLockGateField),
      '9999',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('パスコードが正しくありません'), findsOneWidget);
    expect(find.byKey(AppKeys.homeTitle), findsNothing);
  });

  testWidgets('有効時、正コードで解除され子が表示される', (tester) async {
    await AppLockService(repo).enableWithPasscode('1234');
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppKeys.appLockGateField),
      '1234',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
    expect(find.byKey(AppKeys.appLockGateScreen), findsNothing);
  });

  testWidgets('生成失敗時は fail-open で素通り', (tester) async {
    final throwingRepo = _ThrowingAppLockRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AppLockGate(
          repository: throwingRepo,
          unlockedBuilder: (context) =>
              const Scaffold(key: AppKeys.homeTitle, body: Text('素通り')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
  });
}

/// 読込で例外を投げる試験用リポジトリ（fail-open 検証用）。
class _ThrowingAppLockRepository implements AppLockRepository {
  @override
  bool isEnabled() => throw StateError('boom');

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  AppLockMethod getMethod() => AppLockMethod.none;

  @override
  Future<void> setMethod(AppLockMethod method) async {}

  @override
  String? getPasscodeHash() => null;

  @override
  Future<void> setPasscode(String passcode) async {}

  @override
  Future<void> clearPasscode() async {}

  @override
  bool verifyPasscode(String passcode) => false;
}
