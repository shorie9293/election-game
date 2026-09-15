import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/archive/presentation/election_archive_screen.dart';

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
    ),
    ElectionArchiveEntry(
      electionId: 'e2',
      title: '第2回村長選挙',
      scale: ElectionScale.village,
      winnerId: 'w2',
      winnerName: '天照次郎',
      winnerVotes: 45,
      totalVotes: 100,
      runnerUpVotes: 55,
    ),
    ElectionArchiveEntry(
      electionId: 'e3',
      title: '第1回町長選挙',
      scale: ElectionScale.town,
      winnerId: 'w3',
      winnerName: '天照三郎',
      winnerVotes: 80,
      totalVotes: 100,
      runnerUpVotes: 20,
    ),
  ];

  Future<void> pumpArchive(
    WidgetTester tester, {
    List<ElectionArchiveEntry>? entries,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: ElectionArchiveScreen(entries: entries ?? archiveEntries)),
    );
    await tester.pumpAndSettle();
  }

  group('ElectionArchiveScreen', () {
    testWidgets('サマリー（総選挙数・平均・最大差・最小差）と一覧件数が表示される', (tester) async {
      await pumpArchive(tester);

      expect(find.byKey(AppKeys.archiveTitle), findsOneWidget);
      expect(find.byKey(AppKeys.archiveSummaryCard), findsOneWidget);
      expect(find.text('総選挙数: 3回'), findsOneWidget);
      // 平均: (0.6+0.45+0.8)/3 = 0.6166… → 61.7%
      expect(find.text('平均当選得票率: 61.7%'), findsOneWidget);
      expect(find.text('最大差: 60票'), findsOneWidget);
      // 最小差は runnerUp > winner のケースで負値（-10票）になる
      expect(find.text('最小差: -10票'), findsOneWidget);
      // 当選者別: 太郎1・次郎1・三郎1（名前昇順）
      expect(find.textContaining('天照太郎×1'), findsOneWidget);
      expect(find.byKey(AppKeys.archiveList), findsOneWidget);
      expect(find.text('第1回村長選挙'), findsOneWidget);
      expect(find.text('第2回村長選挙'), findsOneWidget);
      expect(find.text('第1回町長選挙'), findsOneWidget);
    });

    testWidgets('スケール到達状況が表示される', (tester) async {
      await pumpArchive(tester);

      expect(find.byKey(AppKeys.archiveScaleProgression), findsOneWidget);
    });

    testWidgets('スケール絞り込みチップで一覧が絞られる', (tester) async {
      await pumpArchive(tester);

      // 「町」チップをタップ
      await tester.tap(find.byKey(AppKeys.archiveScaleFilter(ElectionScale.town)));
      await tester.pumpAndSettle();

      expect(find.text('第1回町長選挙'), findsOneWidget);
      expect(find.text('第1回村長選挙'), findsNothing);
      expect(find.text('第2回村長選挙'), findsNothing);

      // 「すべて」に戻す
      await tester.tap(find.byKey(AppKeys.archiveFilterAll));
      await tester.pumpAndSettle();
      expect(find.text('第1回村長選挙'), findsOneWidget);
      expect(find.text('第2回村長選挙'), findsOneWidget);
    });

    testWidgets('0件時は空状態を表示する', (tester) async {
      await pumpArchive(tester, entries: const <ElectionArchiveEntry>[]);

      expect(find.byKey(AppKeys.archiveEmptyState), findsOneWidget);
      expect(find.text('まだ選挙の記録がありません'), findsOneWidget);
      expect(find.byKey(AppKeys.archiveSummaryCard), findsNothing);
      expect(find.byKey(AppKeys.archiveList), findsNothing);
    });
  });
}