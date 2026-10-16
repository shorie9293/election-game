import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_settings_screen.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  late InMemoryAppLockRepository repo;

  setUp(() {
    repo = InMemoryAppLockRepository();
  });

  Widget buildScreen() {
    return MaterialApp(
      home: AppLockSettingsScreen(
        key: AppKeys.appLockSettingsScreen,
        repository: repo,
      ),
    );
  }

  Future<void> enterAndSubmit(
    WidgetTester tester, {
    required String passcode,
    required String confirm,
  }) async {
    await tester.enterText(
      find.byKey(AppKeys.appLockPasscodeField),
      passcode,
    );
    await tester.enterText(
      find.byKey(AppKeys.appLockConfirmField),
      confirm,
    );
    await tester.tap(find.byKey(AppKeys.appLockEnableButton));
    await tester.pumpAndSettle();
  }

  testWidgets('初期状態は無効（有効化フォームが表示される）', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.appLockPasscodeField), findsOneWidget);
    expect(find.byKey(AppKeys.appLockEnableButton), findsOneWidget);
  });

  testWidgets('不一致でエラー文言・有効化されない', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await enterAndSubmit(tester, passcode: '1234', confirm: '5678');

    expect(find.byKey(AppKeys.appLockErrorLabel), findsOneWidget);
    expect(find.text('確認用と一致しません'), findsOneWidget);
    expect(repo.isEnabled(), isFalse);
  });

  testWidgets('桁不足・非数字でエラー文言・有効化されない', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await enterAndSubmit(tester, passcode: '123', confirm: '123');
    expect(find.text('4桁の数字を入力せよ'), findsOneWidget);
    expect(repo.isEnabled(), isFalse);

    await enterAndSubmit(tester, passcode: '12a4', confirm: '12a4');
    expect(find.text('4桁の数字を入力せよ'), findsOneWidget);
    expect(repo.isEnabled(), isFalse);
  });

  testWidgets('一致する4桁で有効化され、無効化ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await enterAndSubmit(tester, passcode: '1234', confirm: '1234');

    expect(find.byKey(AppKeys.appLockDisableButton), findsOneWidget);
    expect(find.text('アプリロック有効'), findsOneWidget);
    expect(repo.isEnabled(), isTrue);
    expect(repo.getMethod(), AppLockMethod.passcode);
  });

  testWidgets('無効化すると全状態がクリアされる', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await enterAndSubmit(tester, passcode: '1234', confirm: '1234');
    await tester.tap(find.byKey(AppKeys.appLockDisableButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.appLockEnableButton), findsOneWidget);
    expect(repo.isEnabled(), isFalse);
    expect(repo.getMethod(), AppLockMethod.none);
    expect(repo.getPasscodeHash(), isNull);
  });
}
