import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/models/support_timeline.dart';
import 'package:election_game/domain/repositories/support_timeline_repository.dart';
import 'package:election_game/features/support/presentation/support_timeline_section.dart';
import 'package:election_game/screens/game_screen.dart';

SupportSimulation _simulation(
  List<(String, String, double)> rows, {
  String title = 'テスト選挙',
}) {
  return SupportSimulation(
    electionTitle: title,
    snapshots: [
      for (final row in rows)
        SupportSnapshot(
          candidateId: row.$1,
          candidateName: row.$2,
          supportRate: row.$3,
          rawAffinity: 0.5,
          supporterCount: 3,
        ),
    ],
    voterCount: 10,
    moodLabel: '穏やか',
    stubbornnessLabel: '普通',
    hasHistory: false,
  );
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required SupportTimelineRepository repository,
  required SupportSimulation simulation,
  DateTime Function()? now,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SupportTimelineSection(
            repository: repository,
            simulation: simulation,
            now: now,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('親探針: 世論推移の合成不変条件', () {
    testWidgets('記録→別インスタンスのセクションで復元される（保存到達の合成）', (tester) async {
      final repo = InMemorySupportTimelineRepository();
      var clock = DateTime.utc(2026, 10, 24, 6, 0);

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.4)]),
        now: () => clock,
      );
      expect(find.byKey(AppKeys.supportTimelineEmpty), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(repo.store.length, 1);

      // 画面を作り直す（State は引き継がれない）
      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.4)]),
        now: () => clock,
      );
      expect(find.byKey(AppKeys.supportTimelineEmpty), findsNothing);
      final count = tester.widget<Text>(find.byKey(AppKeys.supportTimelineCount));
      expect(count.data, '1件の記録');
      expect(
        find.byKey(AppKeys.supportTimelineRow(repo.store.first.id)),
        findsOneWidget,
      );
    });

    testWidgets('記録上限200件は add 経由でも古い順に捨てる', (tester) async {
      final repo = InMemorySupportTimelineRepository();
      final base = DateTime.utc(2026, 10, 1);
      for (var i = 0; i < 205; i++) {
        await repo.add(SupportTimelineEntry(
          id: 'support_${i.toString().padLeft(3, '0')}',
          recordedAt: base.add(Duration(minutes: i)),
          electionTitle: 'テスト選挙',
          leaderCandidateId: 'candidate_1',
          leaderCandidateName: '山田太郎',
          leaderSupportRate: 0.4,
          voterCount: 10,
          moodLabel: '穏やか',
        ));
      }
      expect(repo.store.length, 200);
      expect(repo.store.first.id, 'support_005');
      expect(repo.store.last.id, 'support_204');
    });

    testWidgets('GameScreen の棄権経路でも世論が1件自動記録される', (tester) async {
      SharedPreferences.setMockInitialValues({
        'election_game_tutorial_completed': true,
      });
      final repo = InMemorySupportTimelineRepository();

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(supportTimelineRepository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(AppKeys.citizenNameInput), 'タロウ');
      await tester.tap(find.byKey(AppKeys.citizenCreateButton));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(AppKeys.homeElectionButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(AppKeys.homeElectionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.electionProceedButton));
      await tester.pumpAndSettle();
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(AppKeys.debateReactionSilent));
        await tester.pumpAndSettle();
      }
      await tester.tap(find
          .descendant(
            of: find.byKey(AppKeys.debateRatingStars('candidate_1')),
            matching: find.byIcon(Icons.star_border),
          )
          .at(2));
      await tester.pumpAndSettle();
      await tester.tap(find
          .descendant(
            of: find.byKey(AppKeys.debateRatingStars('candidate_2')),
            matching: find.byIcon(Icons.star_border),
          )
          .at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.debateRatingSubmit));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.debateToVoteButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.voteTitle), findsOneWidget);
      expect(repo.store, isEmpty);

      await tester.tap(find.byKey(AppKeys.voteAbstainButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.resultTitle), findsOneWidget);
      await tester.pump();

      expect(repo.store.length, 1);
      expect(repo.store.first.electionTitle, isNotEmpty);
      expect(repo.store.first.leaderCandidateName, isNotEmpty);
      expect(repo.store.first.leaderSupportRate, inInclusiveRange(0.0, 1.0));
    });
  });
}
