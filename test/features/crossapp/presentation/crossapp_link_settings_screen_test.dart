import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/crossapp/data/crossapp_link_code_repository.dart';
import 'package:election_game/features/crossapp/presentation/crossapp_link_settings_screen.dart';

void main() {
  Future<void> pump(
      WidgetTester tester, CrossAppLinkCodeRepository repo) async {
    await tester.pumpWidget(
      MaterialApp(home: CrossAppLinkSettingsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('未連携のときは状態が「未連携」で表示される', (tester) async {
    await pump(tester, InMemoryCrossAppLinkCodeRepository());

    expect(find.byKey(AppKeys.crossAppLinkTitle), findsOneWidget);
    expect(find.byKey(AppKeys.crossAppLinkStatus), findsOneWidget);
    expect(find.textContaining('未連携'), findsWidgets);
  });

  testWidgets('保存済みコードがあると連携済みとして表示される', (tester) async {
    await pump(
      tester,
      InMemoryCrossAppLinkCodeRepository(
          'abcd1234-5678-90ab-cdef-1234567890ab'),
    );

    expect(find.textContaining('連携済み'), findsWidgets);
    expect(find.textContaining('abcd1234'), findsWidgets);
  });

  testWidgets('8文字未満は検証メッセージを出し、保存しない', (tester) async {
    final repo = InMemoryCrossAppLinkCodeRepository();
    await pump(tester, repo);

    await tester.enterText(find.byKey(AppKeys.crossAppLinkCodeInput), 'abc123');
    await tester.tap(find.byKey(AppKeys.crossAppLinkSaveButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.crossAppLinkError), findsOneWidget);
    expect(find.textContaining('8文字以上'), findsWidgets);
    expect(await repo.load(), isNull);
  });

  testWidgets('8文字以上のコードを保存するとリポジトリへ到達する', (tester) async {
    final repo = InMemoryCrossAppLinkCodeRepository();
    await pump(tester, repo);

    await tester.enterText(
      find.byKey(AppKeys.crossAppLinkCodeInput),
      '  abcd1234-5678-90ab-cdef-1234567890ab  ',
    );
    await tester.tap(find.byKey(AppKeys.crossAppLinkSaveButton));
    await tester.pumpAndSettle();

    expect(await repo.load(), 'abcd1234-5678-90ab-cdef-1234567890ab');
    expect(find.byKey(AppKeys.crossAppLinkError), findsNothing);
    expect(find.textContaining('連携済み'), findsWidgets);
  });

  testWidgets('解除ボタンでリポジトリが空になる', (tester) async {
    final repo = InMemoryCrossAppLinkCodeRepository('abcd1234');
    await pump(tester, repo);

    await tester.tap(find.byKey(AppKeys.crossAppLinkClearButton));
    await tester.pumpAndSettle();

    expect(await repo.load(), isNull);
    expect(find.textContaining('未連携'), findsWidgets);
  });
}
