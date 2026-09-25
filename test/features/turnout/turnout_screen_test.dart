import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/domain/services/turnout_service.dart';
import 'package:election_game/features/turnout/presentation/turnout_screen.dart';

void main() {
  final society = SocietyState.initial();
  final election = Election.sample();

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool withCounterfactual = false,
  }) async {
    final turnout = TurnoutService.compute(
      election: election,
      society: society,
      scale: election.scale,
    );
    final counterfactual = withCounterfactual
        ? TurnoutService.counterfactual(
            election: ElectionService.computeElectionResult(election),
            turnout: turnout,
            society: society,
          )
        : null;

    await tester.pumpWidget(
      MaterialApp(
        home: TurnoutScreen(
          electionTitle: election.title,
          turnout: turnout,
          counterfactual: counterfactual,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('TurnoutScreen', () {
    testWidgets('画面と選挙名・投票率が表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.turnoutScreen), findsOneWidget);
      expect(find.byKey(AppKeys.turnoutTitle), findsOneWidget);
      expect(find.text(election.title), findsWidgets);

      final turnout = TurnoutService.compute(
        election: election,
        society: society,
        scale: election.scale,
      );
      final rateText = tester
          .widget<Text>(find.byKey(AppKeys.turnoutRateLabel))
          .data;
      expect(rateText, turnout.turnoutPercentLabel);
    });

    testWidgets('有権者・投票・棄権の内訳が表示される', (tester) async {
      await pumpScreen(tester);

      final summary =
          tester.widget<Text>(find.byKey(AppKeys.turnoutVoterSummary)).data!;
      expect(summary, contains('有権者'));
      expect(summary, contains('投票'));
      expect(summary, contains('棄権'));
    });

    testWidgets('職業別の参加率が全10職ぶん表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.turnoutJobList), findsOneWidget);
      for (final job in Job.values) {
        expect(find.byKey(AppKeys.turnoutJobRow(job.name)), findsOneWidget);
        expect(find.byKey(AppKeys.turnoutJobRate(job.name)), findsOneWidget);
      }
    });

    testWidgets('反実仮想カードは counterfactual が null なら表示されない', (tester) async {
      await pumpScreen(tester, withCounterfactual: false);

      expect(find.byKey(AppKeys.turnoutCounterfactualCard), findsNothing);
      expect(find.byKey(AppKeys.turnoutVerdictLabel), findsNothing);
    });

    testWidgets('反実仮想カードが表示され判定ラベルが出る', (tester) async {
      await pumpScreen(tester, withCounterfactual: true);

      expect(find.byKey(AppKeys.turnoutCounterfactualCard), findsOneWidget);
      final verdict =
          tester.widget<Text>(find.byKey(AppKeys.turnoutVerdictLabel)).data;
      expect(
        verdict,
        anyOf('棄権が当選者を変えた', '棄権があっても当選者は変わらない'),
      );
    });

    testWidgets('反実仮想カードに実際の当選者と全員投票時の当選者が並ぶ', (tester) async {
      await pumpScreen(tester, withCounterfactual: true);

      expect(find.textContaining('実際の当選者'), findsOneWidget);
      expect(find.textContaining('全員投票した場合'), findsOneWidget);
    });

    testWidgets('規模が変われば投票率の表示も変わる（村 vs 市）', (tester) async {
      final village = TurnoutService.compute(
        election: election.copyWith(scale: ElectionScale.village),
        society: society,
        scale: ElectionScale.village,
      );
      final city = TurnoutService.compute(
        election: election.copyWith(scale: ElectionScale.city),
        society: society,
        scale: ElectionScale.city,
      );
      expect(village.turnoutRate, greaterThan(city.turnoutRate));

      await tester.pumpWidget(
        MaterialApp(
          home: TurnoutScreen(
            electionTitle: election.title,
            turnout: village,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<Text>(find.byKey(AppKeys.turnoutRateLabel)).data,
        village.turnoutPercentLabel,
      );
    });

    testWidgets('プレイヤーが棄権すると該当職の票が1減る', (tester) async {
      final player = Citizen.initial(Job.teacher).copyWith(name: '教師');
      final voted = TurnoutService.compute(
        election: election,
        society: society,
        scale: election.scale,
        player: player,
      );
      final abstained = TurnoutService.compute(
        election: election,
        society: society,
        scale: election.scale,
        player: player,
        playerAbstained: true,
      );

      expect(jobVoted(abstained, Job.teacher), jobVoted(voted, Job.teacher) - 1);
      expect(abstained.votesCast, voted.votesCast - 1);
    });
  });
}

/// テスト補助: 職業別の投票者数を取り出す
int jobVoted(TurnoutSnapshot snapshot, Job job) =>
    snapshot.jobBreakdown.firstWhere((j) => j.job == job).voted;
