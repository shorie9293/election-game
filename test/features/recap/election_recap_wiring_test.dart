import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/archive/presentation/election_archive_screen.dart';
import 'package:election_game/features/recap/presentation/election_recap_screen.dart';

void main() {
  final archiveEntries = [
    ElectionArchiveEntry(
      electionId: 'e1',
      title: '第1回村長選挙',
      scale: ElectionScale.village,
      winnerId: 'w1',
      winnerName: '天照太郎',
      winnerVotes: 60,
      totalVotes: 100,
      runnerUpVotes: 40,
      occurredAt: DateTime(2026, 1, 2),
    ),
  ];

  testWidgets('アーカイブ画面の導線ボタンから振り返り画面へ遷移する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ElectionArchiveScreen(entries: archiveEntries),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.archiveRecapButton), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.archiveRecapButton));
    await tester.pumpAndSettle();

    expect(find.byType(ElectionRecapScreen), findsOneWidget);
    expect(find.byKey(AppKeys.recapTitle), findsOneWidget);
    expect(find.text('選挙の振り返り'), findsOneWidget);
  });
}
