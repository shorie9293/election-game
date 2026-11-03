import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/help/presentation/help_screen.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';

Future<void> _pumpHelp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
  await tester.pumpAndSettle();
}

void main() {
  group('HelpScreen', () {
    testWidgets('AppBar に「遊び方・ヘルプ」が出る', (tester) async {
      await _pumpHelp(tester);

      expect(find.byKey(AppKeys.helpScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('遊び方・ヘルプ'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('全章が表示される', (tester) async {
      await _pumpHelp(tester);

      for (final step in TutorialStep.values) {
        expect(
          find.text(step.label),
          findsWidgets,
          reason: '${step.label} の章が無い',
        );
      }
    });

    testWidgets('検索で絞り込める', (tester) async {
      await _pumpHelp(tester);

      await tester.enterText(find.byKey(AppKeys.helpSearchField), '投票');
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.helpTopicTile(TutorialStep.vote.name)),
          findsOneWidget);
      expect(
        find.byKey(AppKeys.helpTopicTile(TutorialStep.debate.name)),
        findsNothing,
      );
    });

    testWidgets('該当なしなら0件メッセージ', (tester) async {
      await _pumpHelp(tester);

      await tester.enterText(
        find.byKey(AppKeys.helpSearchField),
        '存在しない語句zzz',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.helpEmptyState), findsOneWidget);
      expect(find.text('該当するヘルプがありません'), findsOneWidget);
    });

    testWidgets('クリアで全件に戻る', (tester) async {
      await _pumpHelp(tester);

      await tester.enterText(
        find.byKey(AppKeys.helpSearchField),
        '存在しない語句zzz',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.helpEmptyState), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.helpSearchClear));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.helpEmptyState), findsNothing);
      expect(
        find.byKey(AppKeys.helpTopicTile(TutorialStep.home.name)),
        findsOneWidget,
      );
    });
  });
}
