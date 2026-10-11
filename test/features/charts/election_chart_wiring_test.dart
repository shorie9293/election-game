import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/archive/presentation/election_archive_screen.dart';

ElectionArchiveEntry _entry(String id, DateTime at) {
  return ElectionArchiveEntry(
    electionId: id,
    title: '選挙$id',
    scale: ElectionScale.town,
    winnerId: 'w$id',
    winnerName: '太郎',
    winnerVotes: 60,
    totalVotes: 100,
    runnerUpVotes: 40,
    occurredAt: at,
  );
}

void main() {
  testWidgets('アーカイブ画面のAppBarボタンからグラフ画面へ遷移する', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ElectionArchiveScreen(
          entries: [
            _entry('election_1', DateTime(2026, 1, 1)),
            _entry('election_2', DateTime(2026, 2, 1)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.archiveChartButton), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.archiveChartButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.chartScreen), findsOneWidget);
    expect(find.byKey(AppKeys.chartSummaryCard), findsOneWidget);
  });

  testWidgets('アーカイブ画面の既存ボタン（振り返り）が壊れていない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ElectionArchiveScreen(
          entries: [_entry('election_1', DateTime(2026, 1, 1))],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.archiveRecapButton), findsOneWidget);
    expect(find.byIcon(Icons.insights), findsOneWidget);
  });
}
