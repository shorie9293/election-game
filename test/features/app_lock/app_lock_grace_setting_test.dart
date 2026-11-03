import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_settings_screen.dart';
import 'package:election_game/core/infrastructure/lock_reload_policy.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  late InMemoryAppLockRepository repo;

  setUp(() {
    repo = InMemoryAppLockRepository();
  });

  Widget buildScreen() => MaterialApp(
        home: AppLockSettingsScreen(
          key: AppKeys.appLockSettingsScreen,
          repository: repo,
        ),
      );

  Future<void> enable(WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AppKeys.appLockPasscodeField), '1234');
    await tester.enterText(find.byKey(AppKeys.appLockConfirmField), '1234');
    await tester.tap(find.byKey(AppKeys.appLockEnableButton));
    await tester.pumpAndSettle();
  }

  testWidgets('有効時のみ再施錠猶予のドロップダウンが出る（既定=即時）', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.appLockGraceDropdown), findsNothing);

    await enable(tester);
    expect(find.byKey(AppKeys.appLockGraceDropdown), findsOneWidget);
    expect(
      find.text(LockReloadPolicy.graceLabel(0)),
      findsOneWidget,
    );
  });

  testWidgets('猶予を選ぶとリポジトリへ永続化される', (tester) async {
    await enable(tester);

    await tester.tap(find.byKey(AppKeys.appLockGraceDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LockReloadPolicy.graceLabel(60)).last);
    await tester.pumpAndSettle();

    expect(repo.getRelockGraceSeconds(), 60);
    expect(
      tester
          .widget<DropdownButton<int>>(
            find.byKey(AppKeys.appLockGraceDropdown),
          )
          .value,
      60,
    );
  });

  testWidgets('狭い画面でも有効時レイアウトが overflow しない', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await enable(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(AppKeys.appLockDisableButton), findsOneWidget);
  });
}
