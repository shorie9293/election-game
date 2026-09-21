import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/support/presentation/support_simulation_screen.dart';

void main() {
  final candidates = Candidate.samples();

  final society = SocietyState(
    happiness: 60.0,
    mood: 0.3,
    electionCount: 1,
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Candidate>? candidatesArg,
    List<Citizen>? votersOverride,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SupportSimulationScreen(
          candidates: candidatesArg ?? candidates,
          society: society,
          votersOverride: votersOverride,
        ),
      ),
    );
    // 繰り返しアニメーションがあるため pumpAndSettle は使わない
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('SupportSimulationScreen', () {
    testWidgets('タイトル・世論カード・有権者数・脚注が表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.supportTitle), findsOneWidget);
      expect(find.byKey(AppKeys.supportMoodCard), findsOneWidget);
      expect(find.byKey(AppKeys.supportVoterCount), findsOneWidget);
      expect(find.byKey(AppKeys.supportNote), findsOneWidget);
    });

    testWidgets('首位カードが表示され、初回選挙の補足文言が付く', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(AppKeys.supportLeaderCard), findsOneWidget);
      // lastElection 未指定なので初回の選挙
      expect(find.text('今回が初回の選挙'), findsOneWidget);
    });

    testWidgets('各候補者の行と支持率ラベルが表示される', (tester) async {
      await pumpScreen(tester);

      for (final candidate in candidates) {
        expect(
          find.byKey(AppKeys.supportCandidateRow(candidate.id)),
          findsOneWidget,
        );
        expect(
          find.byKey(AppKeys.supportCandidateRate(candidate.id)),
          findsOneWidget,
        );
      }
      expect(find.byKey(AppKeys.supportEmptyState), findsNothing);
    });

    testWidgets('supportPercentLabel の書式が「N.N%」と一致する', (tester) async {
      await pumpScreen(tester);

      final rateFinder =
          find.byKey(AppKeys.supportCandidateRate('candidate_1'));
      expect(rateFinder, findsOneWidget);
      final text = tester.widget<Text>(rateFinder).data!;
      expect(text, matches(RegExp(r'^\d+\.\d%$')));
      expect(text, endsWith('%'));
    });

    testWidgets('候補者が空のとき空状態が出て首位カードは出ない', (tester) async {
      await pumpScreen(tester, candidatesArg: []);

      expect(find.byKey(AppKeys.supportEmptyState), findsOneWidget);
      expect(find.byKey(AppKeys.supportLeaderCard), findsNothing);
    });

    testWidgets('votersOverride を渡すと有権者数の表示が変わる', (tester) async {
      final voters = List.generate(
        3,
        (i) => Citizen(
          name: '有権者$i',
          job: Job.farmer,
          concerns: [Concern.agriculture],
          lifeParams: const {
            'lifeCost': 50,
            'healthcare': 50,
            'education': 50,
            'employment': 50,
            'environment': 50,
            'safety': 50,
          },
        ),
      );
      await pumpScreen(tester, votersOverride: voters);

      expect(find.text('3人の有権者で試算'), findsOneWidget);
    });

    testWidgets('支持の厚い職業層の文言が表示される', (tester) async {
      await pumpScreen(tester);

      expect(
        find.byKey(AppKeys.supportCandidateJob('candidate_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(AppKeys.supportCandidateJob('candidate_2')),
        findsOneWidget,
      );
    });

    testWidgets('スナップショットは支持率降順で表示される', (tester) async {
      await pumpScreen(tester);

      // 画面に表示された順（支持率降順整列済み）で割合ラベルを拾う
      final rateWidgets = tester.widgetList<Text>(
        find.byWidgetPredicate(
          (w) => w.key is Key &&
              (w.key as Key).toString().startsWith(
                  "[<'support_candidate_rate_"),
        ),
      ).toList();
      expect(rateWidgets.length, candidates.length);
      final rates = rateWidgets
          .map((w) => double.parse(w.data!.replaceAll('%', '')))
          .toList();
      for (var i = 0; i < rates.length - 1; i++) {
        expect(rates[i], greaterThanOrEqualTo(rates[i + 1]));
      }
    });
  });
}
