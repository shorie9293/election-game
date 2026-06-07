import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/daily_event.dart';
import 'package:election_game/domain/models/concern_evolution.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  group('HomeScreen', () {
    final testCitizen = Citizen(
      name: 'テスト太郎',
      job: Job.farmer,
      concerns: [Concern.agriculture],
      lifeParams: {
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 70,
        'safety': 50,
      },
    );

    final testSociety = SocietyState(
      happiness: 65.0,
      mood: 0.4,
      electionCount: 2,
    );

    final testDailyEvent = DailyEvent(
      title: '町内清掃',
      description: '地域の清掃活動が行われた',
      icon: '🧹',
    );

    Widget buildHomeScreen({
      Citizen? citizen,
      SocietyState? societyState,
      int remainingTurns = 10,
      DailyEvent? dailyEvent,
      List<ConcernEvolution> concernEvolutions = const [],
      VoidCallback? onStartElection,
      void Function(DailyAction)? onActionSelected,
      void Function(DailyEvent, EventChoice)? onChoiceSelected,
    }) {
      return MaterialApp(
        home: HomeScreen(
          citizen: citizen ?? testCitizen,
          societyState: societyState ?? testSociety,
          remainingTurns: remainingTurns,
          dailyEvent: dailyEvent,
          concernEvolutions: concernEvolutions,
          onStartElection: onStartElection,
          onActionSelected: onActionSelected,
          onChoiceSelected: onChoiceSelected,
        ),
      );
    }

    testWidgets('should display citizen name in AppBar title', (tester) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
      expect(find.text('天照町 — テスト太郎'), findsOneWidget);
    });

    testWidgets('should display citizen info card with name and job label',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byKey(AppKeys.homeCitizenInfo), findsOneWidget);
      expect(find.text('テスト太郎'), findsOneWidget);
      expect(find.text('職業: 農家'), findsOneWidget);
    });

    testWidgets('should display society mood label and happiness',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byKey(AppKeys.homeSocietyMood), findsOneWidget);
      expect(find.text('健全な対立'), findsOneWidget);
      expect(find.text('幸福度: 65'), findsOneWidget);
    });

    testWidgets('should display daily event when dailyEvent is provided and has no choices',
        (tester) async {
      await tester.pumpWidget(
        buildHomeScreen(dailyEvent: testDailyEvent),
      );

      expect(find.byKey(AppKeys.homeDailyEvent), findsOneWidget);
      expect(find.text('町内清掃'), findsOneWidget);
      expect(find.text('地域の清掃活動が行われた'), findsOneWidget);
      expect(find.text('🧹'), findsOneWidget);
    });

    testWidgets('should NOT display daily event when dailyEvent is null',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen(dailyEvent: null));

      expect(find.byKey(AppKeys.homeDailyEvent), findsNothing);
      expect(find.text('町内清掃'), findsNothing);
    });

    testWidgets('should display remaining turns countdown',
        (tester) async {
      await tester.pumpWidget(
        buildHomeScreen(remainingTurns: 7),
      );

      expect(find.byKey(AppKeys.homeCountdown), findsOneWidget);
      expect(find.text('次回選挙まで'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('should display three action buttons when remainingTurns > 0',
        (tester) async {
      await tester.pumpWidget(
        buildHomeScreen(remainingTurns: 5),
      );

      // 3つのアクションボタンが表示される
      expect(find.byKey(AppKeys.homeActionTalkNpc), findsOneWidget);
      expect(find.byKey(AppKeys.homeActionGatherInfo), findsOneWidget);
      expect(find.byKey(AppKeys.homeActionRest), findsOneWidget);
      // 選挙ボタンは非表示
      expect(find.byKey(AppKeys.homeElectionButton), findsNothing);
    });

    testWidgets('should display election button when remainingTurns <= 0',
        (tester) async {
      await tester.pumpWidget(
        buildHomeScreen(remainingTurns: 0),
      );

      expect(find.byKey(AppKeys.homeElectionButton), findsOneWidget);
      expect(find.text('選挙に行く'), findsOneWidget);
      // アクションボタンは非表示
      expect(find.byKey(AppKeys.homeActionTalkNpc), findsNothing);
      expect(find.byKey(AppKeys.homeActionGatherInfo), findsNothing);
      expect(find.byKey(AppKeys.homeActionRest), findsNothing);
    });

    testWidgets('should call onActionSelected when NPC button tapped',
        (tester) async {
      DailyAction? receivedAction;
      await tester.pumpWidget(
        buildHomeScreen(
          remainingTurns: 3,
          onActionSelected: (action) => receivedAction = action,
        ),
      );

      await tester.ensureVisible(find.byKey(AppKeys.homeActionTalkNpc));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.homeActionTalkNpc));
      expect(receivedAction, DailyAction.talkToNpc);
    });

    testWidgets('should call onActionSelected when gather info button tapped',
        (tester) async {
      DailyAction? receivedAction;
      await tester.pumpWidget(
        buildHomeScreen(
          remainingTurns: 3,
          onActionSelected: (action) => receivedAction = action,
        ),
      );

      await tester.ensureVisible(find.byKey(AppKeys.homeActionGatherInfo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.homeActionGatherInfo));
      expect(receivedAction, DailyAction.gatherInfo);
    });

    testWidgets('should call onActionSelected when rest button tapped',
        (tester) async {
      DailyAction? receivedAction;
      await tester.pumpWidget(
        buildHomeScreen(
          remainingTurns: 3,
          onActionSelected: (action) => receivedAction = action,
        ),
      );

      await tester.ensureVisible(find.byKey(AppKeys.homeActionRest));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.homeActionRest));
      expect(receivedAction, DailyAction.rest);
    });

    testWidgets('should show choice dialog when dailyEvent has choices',
        (tester) async {
      final choiceEvent = DailyEvent(
        title: '選挙の話をする？',
        description: '町民が話しかけてきた。',
        icon: '🗣️',
        actionType: DailyAction.talkToNpc,
        choices: [
          const EventChoice(
            label: 'しっかり話を聞く',
            resultDescription: '本音が聞けた。',
            effects: {'happiness': 2},
          ),
          const EventChoice(
            label: '軽く流す',
            resultDescription: '当たり障りなく答えた。',
          ),
        ],
      );

      await tester.pumpWidget(
        buildHomeScreen(
          remainingTurns: 3,
          dailyEvent: choiceEvent,
        ),
      );
      // ダイアログが表示されているはず
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.homeChoiceDialog), findsOneWidget);
      expect(find.text('しっかり話を聞く'), findsOneWidget);
      expect(find.text('軽く流す'), findsOneWidget);
    });

    testWidgets('should call onChoiceSelected when choice is tapped',
        (tester) async {
      DailyEvent? capturedEvent;
      EventChoice? capturedChoice;
      final choiceEvent = DailyEvent(
        title: '選挙の話をする？',
        description: '町民が話しかけてきた。',
        icon: '🗣️',
        actionType: DailyAction.talkToNpc,
        choices: [
          const EventChoice(
            label: 'しっかり話を聞く',
            resultDescription: '本音が聞けた。',
            effects: {'happiness': 2},
          ),
          const EventChoice(
            label: '軽く流す',
            resultDescription: '当たり障りなく答えた。',
          ),
        ],
      );

      await tester.pumpWidget(
        buildHomeScreen(
          remainingTurns: 3,
          dailyEvent: choiceEvent,
          onChoiceSelected: (event, choice) {
            capturedEvent = event;
            capturedChoice = choice;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.homeChoiceDialog), findsOneWidget);
      await tester.tap(find.text('しっかり話を聞く'));
      await tester.pumpAndSettle();

      expect(capturedEvent, isNotNull);
      expect(capturedChoice, isNotNull);
      expect(capturedChoice!.label, 'しっかり話を聞く');
    });

    testWidgets('should call onStartElection when election button tapped',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(
        buildHomeScreen(
          remainingTurns: 0,
          onStartElection: () => called = true,
        ),
      );

      await tester.ensureVisible(find.byKey(AppKeys.homeElectionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.homeElectionButton));
      expect(called, isTrue);
    });

    testWidgets('should display life params card with param values',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byKey(AppKeys.homeLifeParams), findsOneWidget);
      expect(find.text('💰 生活費'), findsOneWidget);
      expect(find.text('🏥 医療'), findsOneWidget);
      expect(find.text('🏫 教育'), findsOneWidget);
      expect(find.text('🏭 仕事'), findsOneWidget);
      expect(find.text('🌳 環境'), findsOneWidget);
      expect(find.text('🚔 治安'), findsOneWidget);
      expect(find.text('50'), findsNWidgets(5));
      expect(find.text('70'), findsOneWidget);
    });

    // --- Concern growth tests ---

    testWidgets('should NOT show concern growth card when no acquired concerns',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen(concernEvolutions: []));

      expect(find.byKey(AppKeys.homeConcernGrowth), findsNothing);
    });

    testWidgets('should NOT show concern growth card when only initial concerns',
        (tester) async {
      await tester.pumpWidget(
        buildHomeScreen(
          concernEvolutions: [
            ConcernEvolution.initial(Concern.agriculture),
            ConcernEvolution.initial(Concern.economy),
          ],
        ),
      );

      expect(find.byKey(AppKeys.homeConcernGrowth), findsNothing);
    });

    testWidgets('should show concern growth card when acquired concerns exist',
        (tester) async {
      await tester.pumpWidget(
        buildHomeScreen(
          concernEvolutions: [
            ConcernEvolution.initial(Concern.agriculture),
            ConcernEvolution(
              concern: Concern.education,
              acquiredAtElection: 2,
              reason: '討論で教育の重要性に気づいた',
            ),
          ],
        ),
      );

      expect(find.byKey(AppKeys.homeConcernGrowth), findsOneWidget);
      expect(find.text('政治的成長'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('教育政策'), findsOneWidget);
      expect(find.text('討論で教育の重要性に気づいた'), findsOneWidget);
    });

    testWidgets(
        'should show multiple acquired concerns with correct labels and reasons',
        (tester) async {
      await tester.pumpWidget(
        buildHomeScreen(
          concernEvolutions: [
            ConcernEvolution.initial(Concern.agriculture),
            ConcernEvolution(
              concern: Concern.education,
              acquiredAtElection: 1,
              reason: '討論で教育の重要性に気づいた',
            ),
            ConcernEvolution(
              concern: Concern.environment,
              acquiredAtElection: 2,
              reason: '選挙結果から環境問題に関心',
            ),
          ],
        ),
      );

      expect(find.byKey(AppKeys.homeConcernGrowth), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('教育政策'), findsOneWidget);
      expect(find.text('環境政策'), findsOneWidget);
      expect(find.text('討論で教育の重要性に気づいた'), findsOneWidget);
      expect(find.text('選挙結果から環境問題に関心'), findsOneWidget);
    });
  });
}
