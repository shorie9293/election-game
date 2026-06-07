import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';
import 'package:election_game/features/tutorial/presentation/tutorial_overlay.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  group('TutorialOverlay', () {
    Widget buildTestWidget({
      required TutorialStep step,
      required VoidCallback onNext,
      required VoidCallback onSkip,
      required Widget child,
      TutorialOverlayPosition position = TutorialOverlayPosition.bottom,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TutorialOverlay(
            step: step,
            onNext: onNext,
            onSkip: onSkip,
            position: position,
            child: child,
          ),
        ),
      );
    }

    testWidgets('吹き出しテキストが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.home,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
        ),
      );

      expect(find.byKey(AppKeys.tutorialOverlay), findsOneWidget);
      expect(find.byKey(AppKeys.tutorialText), findsOneWidget);
      expect(find.byKey(AppKeys.tutorialText), findsOneWidget);
    });

    testWidgets('子Widgetが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.citizenCreate,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
        ),
      );

      expect(find.text('子Widget'), findsOneWidget);
    });

    testWidgets('次へボタンが存在する', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.debate,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
        ),
      );

      expect(find.byKey(AppKeys.tutorialNextButton), findsOneWidget);
    });

    testWidgets('スキップボタンが存在する', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.vote,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
        ),
      );

      expect(find.byKey(AppKeys.tutorialSkipButton), findsOneWidget);
    });

    testWidgets('次へボタンをタップするとコールバックが呼ばれる', (tester) async {
      bool nextCalled = false;
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.home,
          onNext: () => nextCalled = true,
          onSkip: () {},
          child: const Text('子Widget'),
        ),
      );

      await tester.tap(find.byKey(AppKeys.tutorialNextButton));
      expect(nextCalled, isTrue);
    });

    testWidgets('スキップボタンをタップするとコールバックが呼ばれる', (tester) async {
      bool skipCalled = false;
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.vote,
          onNext: () {},
          onSkip: () => skipCalled = true,
          child: const Text('子Widget'),
        ),
      );

      await tester.tap(find.byKey(AppKeys.tutorialSkipButton));
      expect(skipCalled, isTrue);
    });

    testWidgets('Semanticsが次へボタンに付与されている', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.citizenCreate,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
        ),
      );

      final semantics = tester.getSemantics(find.byKey(AppKeys.tutorialNextButton));
      expect(semantics, isNotNull);
    });

    testWidgets('Semanticsがスキップボタンに付与されている', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.citizenCreate,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
        ),
      );

      final semantics = tester.getSemantics(find.byKey(AppKeys.tutorialSkipButton));
      expect(semantics, isNotNull);
    });

    testWidgets('position引数でtopを指定できる', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.home,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
          position: TutorialOverlayPosition.top,
        ),
      );

      expect(find.byKey(AppKeys.tutorialOverlay), findsOneWidget);
      expect(find.byKey(AppKeys.tutorialText), findsOneWidget);
    });

    testWidgets('position引数でcenterを指定できる', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          step: TutorialStep.home,
          onNext: () {},
          onSkip: () {},
          child: const Text('子Widget'),
          position: TutorialOverlayPosition.center,
        ),
      );

      expect(find.byKey(AppKeys.tutorialOverlay), findsOneWidget);
      expect(find.byKey(AppKeys.tutorialText), findsOneWidget);
    });
  });
}
