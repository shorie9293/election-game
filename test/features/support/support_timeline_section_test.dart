import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/models/support_timeline.dart';
import 'package:election_game/domain/repositories/support_timeline_repository.dart';
import 'package:election_game/features/support/presentation/support_timeline_section.dart';

/// 候補者 (id, 名前, 支持率) からシミュレーションを組み立てる。
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

SupportTimelineEntry _entry({
  required String id,
  required DateTime at,
  String candidateId = 'candidate_1',
  String candidateName = '山田太郎',
  double rate = 0.3,
}) {
  return SupportTimelineEntry(
    id: id,
    recordedAt: at,
    electionTitle: 'テスト選挙',
    leaderCandidateId: candidateId,
    leaderCandidateName: candidateName,
    leaderSupportRate: rate,
    voterCount: 10,
    moodLabel: '穏やか',
  );
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required SupportTimelineRepository repository,
  required SupportSimulation simulation,
  DateTime Function()? now,
  int maxRows = 20,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SupportTimelineSection(
            repository: repository,
            simulation: simulation,
            now: now,
            maxRows: maxRows,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SupportTimelineSection', () {
    testWidgets('記録が無ければ空状態を表示する', (tester) async {
      final repo = InMemorySupportTimelineRepository();

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.5)]),
      );

      expect(find.byKey(AppKeys.supportTimelineEmpty), findsOneWidget);
      expect(find.byKey(AppKeys.supportTimelineTitle), findsOneWidget);
      expect(find.text('0件の記録'), findsOneWidget);
      expect(find.text('記録なし'), findsOneWidget);
    });

    testWidgets('記録ボタン押下で repository に1件永続化される', (tester) async {
      final repo = InMemorySupportTimelineRepository();
      final at = DateTime.utc(2026, 1, 2, 3, 4, 5);

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.5)]),
        now: () => at,
      );

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();

      expect(repo.store, hasLength(1));
      expect(repo.store.single.leaderCandidateName, '山田太郎');
      expect(find.text('世論を記録しました'), findsOneWidget);
      expect(find.text('1件の記録'), findsOneWidget);
    });

    testWidgets('2回記録すると2件になり、2件目の行に差分ラベルが出る', (tester) async {
      final repo = InMemorySupportTimelineRepository();
      var clock = DateTime.utc(2026, 1, 2, 3, 4, 5);
      DateTime now() {
        final value = clock;
        clock = clock.add(const Duration(minutes: 1));
        return value;
      }

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.5)]),
        now: now,
      );

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();

      expect(repo.store, hasLength(2));
      final secondId = repo.store.last.id;
      final secondRow = find.byKey(AppKeys.supportTimelineRow(secondId));
      expect(secondRow, findsOneWidget);
      // 2件目のみ差分ラベルを持つ（初回行には出ない）
      expect(
        find.descendant(of: secondRow, matching: find.text('±0.0pt')),
        findsOneWidget,
      );
      expect(find.text('±0.0pt'), findsOneWidget);
    });

    testWidgets('件数ラベルは実際に描画した行数と一致する', (tester) async {
      final repo = InMemorySupportTimelineRepository();
      var clock = DateTime.utc(2026, 1, 2, 3, 4, 5);
      DateTime now() {
        final value = clock;
        clock = clock.add(const Duration(minutes: 1));
        return value;
      }

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.5)]),
        now: now,
      );

      expect(find.text('0件の記録'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();
      expect(find.text('1件の記録'), findsOneWidget);
      expect(find.byKey(AppKeys.supportTimelineCount), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();
      expect(find.text('2件の記録'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(AppKeys.supportTimelineCount)).data,
        '2件の記録',
      );
    });

    testWidgets('now 注入が recordedAt に反映される', (tester) async {
      final repo = InMemorySupportTimelineRepository();
      final at = DateTime.utc(2026, 7, 8, 9, 10, 11);

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.42)]),
        now: () => at,
      );

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();

      expect(repo.store.single.recordedAt, at);
      expect(repo.store.single.recordedAt.isUtc, isTrue);
      expect(find.text('42.0%'), findsOneWidget);
    });

    testWidgets('首位が交代した行にバッジを表示する', (tester) async {
      final repo = InMemorySupportTimelineRepository([
        _entry(
          id: 'old',
          at: DateTime.utc(2026, 1, 1),
          candidateId: 'candidate_2',
          candidateName: '佐藤花子',
          rate: 0.6,
        ),
      ]);

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.5)]),
        now: () => DateTime.utc(2026, 1, 2),
      );

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();

      final newId = repo.store.last.id;
      expect(repo.store, hasLength(2));
      expect(
        find.byKey(AppKeys.supportTimelineLeaderChanged(newId)),
        findsOneWidget,
      );
      expect(find.text('首位交代'), findsOneWidget);
      expect(find.text('-10.0pt'), findsOneWidget);
    });

    testWidgets('simulation が空なら記録しても件数は増えない', (tester) async {
      final repo = InMemorySupportTimelineRepository();

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation(const []),
        now: () => DateTime.utc(2026, 1, 2),
      );

      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pumpAndSettle();

      expect(repo.store, isEmpty);
      expect(find.text('0件の記録'), findsOneWidget);
      expect(find.text('世論を記録しました'), findsNothing);
    });

    testWidgets('maxRows を超える記録は描画されず件数ラベルも描画数になる', (tester) async {
      final repo = InMemorySupportTimelineRepository([
        for (var i = 0; i < 5; i++)
          _entry(
            id: 'e$i',
            at: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
            rate: 0.2 + i * 0.05,
          ),
      ]);

      await _pumpSection(
        tester,
        repository: repo,
        simulation: _simulation([('candidate_1', '山田太郎', 0.5)]),
        maxRows: 3,
      );

      expect(find.text('3件の記録'), findsOneWidget);
      expect(find.byKey(AppKeys.supportTimelineRow('e0')), findsNothing);
      expect(find.byKey(AppKeys.supportTimelineRow('e1')), findsNothing);
      expect(find.byKey(AppKeys.supportTimelineRow('e2')), findsOneWidget);
      expect(find.byKey(AppKeys.supportTimelineRow('e3')), findsOneWidget);
      expect(find.byKey(AppKeys.supportTimelineRow('e4')), findsOneWidget);
    });
  });
}
