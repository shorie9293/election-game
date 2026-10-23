import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/repositories/support_timeline_repository.dart';
import 'package:election_game/features/support/presentation/support_simulation_screen.dart';

final _society = SocietyState(
  happiness: 60.0,
  mood: 0.3,
  electionCount: 1,
);

/// 画面には繰り返しアニメーションがあるため pumpAndSettle は使わない。
Future<void> _pumpScreen(
  WidgetTester tester, {
  SupportTimelineRepository? repository,
  DateTime Function()? now,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SupportSimulationScreen(
        candidates: Candidate.samples(),
        society: _society,
        electionTitle: 'テスト選挙',
        timelineRepository: repository,
        now: now,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('SupportSimulationScreen × 世論の推移', () {
    testWidgets('timelineRepository 未注入なら推移セクションを描画しない', (tester) async {
      await _pumpScreen(tester);

      expect(find.byKey(AppKeys.supportNote), findsOneWidget);
      expect(find.byKey(AppKeys.supportTimelineTitle), findsNothing);
    });

    testWidgets('timelineRepository 注入時は脚注の下に推移セクションを描画する', (tester) async {
      final repo = InMemorySupportTimelineRepository();
      final at = DateTime.utc(2026, 2, 3, 4, 5, 6);

      await _pumpScreen(tester, repository: repo, now: () => at);

      expect(find.byKey(AppKeys.supportTimelineTitle), findsOneWidget);
      expect(find.byKey(AppKeys.supportTimelineEmpty), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(AppKeys.supportTimelineRecordButton),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(AppKeys.supportTimelineRecordButton));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.store, hasLength(1));
      expect(repo.store.single.electionTitle, 'テスト選挙');
      expect(repo.store.single.recordedAt, at);
      expect(find.text('1件の記録'), findsOneWidget);
      // 既存の脚注は不変
      expect(find.byKey(AppKeys.supportNote), findsOneWidget);
    });
  });
}
