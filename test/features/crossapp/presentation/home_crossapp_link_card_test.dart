import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/crossapp/data/crossapp_link_code_repository.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

/// ホーム画面最下部の「クロスアプリ連携（学びの循環）」カードの導線の試練。
void main() {
  Future<void> pumpHome(
    WidgetTester tester,
    CrossAppLinkCodeRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          citizen: Citizen.initial(Job.farmer),
          societyState: SocietyState.initial(),
          remainingTurns: 0,
          crossAppLinkRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ホーム最下部に連携カードがあり、未連携を表示する', (tester) async {
    await pumpHome(tester, InMemoryCrossAppLinkCodeRepository());

    await tester.scrollUntilVisible(
      find.byKey(AppKeys.homeCrossAppLinkCard),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(AppKeys.homeCrossAppLinkCard), findsOneWidget);
    expect(find.textContaining('クロスアプリ連携'), findsWidgets);
    expect(find.textContaining('未連携'), findsWidgets);
  });

  testWidgets('連携済みならプレフィックスを表示する', (tester) async {
    await pumpHome(
      tester,
      InMemoryCrossAppLinkCodeRepository(
          'abcd1234-5678-90ab-cdef-1234567890ab'),
    );

    await tester.scrollUntilVisible(
      find.byKey(AppKeys.homeCrossAppLinkCard),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.textContaining('連携済み'), findsWidgets);
    expect(find.textContaining('abcd1234'), findsWidgets);
  });

  testWidgets('設定ボタンから連携設定画面へ遷移する', (tester) async {
    await pumpHome(tester, InMemoryCrossAppLinkCodeRepository());

    await tester.scrollUntilVisible(
      find.byKey(AppKeys.homeCrossAppLinkButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(AppKeys.homeCrossAppLinkButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.crossAppLinkTitle), findsOneWidget);
    expect(find.byKey(AppKeys.crossAppLinkCodeInput), findsOneWidget);
  });
}
