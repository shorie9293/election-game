import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/manifesto.dart';
import 'package:election_game/features/manifesto/presentation/manifesto_tracker_screen.dart';

void main() {
  Widget buildScreen({List<ManifestoRecord> records = const []}) {
    return MaterialApp(
      home: ManifestoTrackerScreen(records: records),
    );
  }

  ManifestoRecord buildRecord({
    String electionId = 'e1',
    String winnerName = '太郎',
    String title = '村長選挙',
    DateTime? occurredAt,
  }) {
    return ManifestoRecord(
      electionId: electionId,
      title: title,
      winnerId: 'c1',
      winnerName: winnerName,
      occurredAt: occurredAt,
      pledges: [
        const ManifestoPledge(
          lifeParamKey: 'healthcare',
          promisedDelta: 10,
          actualDelta: 10,
          policyTitles: ['病院を増やす'],
        ),
        const ManifestoPledge(
          lifeParamKey: 'education',
          promisedDelta: 10,
          actualDelta: 5,
          policyTitles: ['学校を増やす'],
        ),
      ],
    );
  }

  group('ManifestoTrackerScreen', () {
    testWidgets('空状態: records 0件なら emptyState を表示する', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen());

      expect(find.byKey(AppKeys.manifestoEmptyState), findsOneWidget);
      expect(find.byKey(AppKeys.manifestoTitle), findsOneWidget);
      // 空のときはサマリー・件数ラベルを出さない
      expect(find.byKey(AppKeys.manifestoSummary), findsNothing);
      expect(find.byKey(AppKeys.manifestoListCount), findsNothing);
    });

    testWidgets('record 表示: カード・日付・percentLabel・pledge行が出る',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(records: [
        buildRecord(occurredAt: DateTime(2026, 10, 9)),
      ]));

      expect(
        find.byKey(AppKeys.manifestoRecordCard('e1')),
        findsOneWidget,
      );
      expect(find.text('当選者: 太郎'), findsOneWidget);
      expect(find.text('村長選挙'), findsOneWidget);
      expect(find.text('2026/10/09'), findsOneWidget);
      // rate平均 = (1.0 + 0.5) / 2 = 0.75 → 75%
      expect(find.text('75%'), findsOneWidget);
      expect(
        find.byKey(AppKeys.manifestoPledgeRow('e1', 'healthcare')),
        findsOneWidget,
      );
      expect(
        find.byKey(AppKeys.manifestoPledgeRow('e1', 'education')),
        findsOneWidget,
      );
      expect(find.textContaining('🏥 医療'), findsOneWidget);
      expect(find.textContaining('実現'), findsWidgets);
    });

    testWidgets('summary 表示: 件数・平均実現率・実現公約数', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(records: [buildRecord()]));

      expect(find.byKey(AppKeys.manifestoSummary), findsOneWidget);
      expect(find.byKey(AppKeys.manifestoListCount), findsOneWidget);
      expect(find.text('1件'), findsOneWidget);
      expect(find.textContaining('記録件数: 1件'), findsOneWidget);
      expect(find.textContaining('平均実現率: 75%'), findsOneWidget);
      expect(find.textContaining('実現公約数: 1'), findsOneWidget);
    });

    testWidgets('検索絞込: winnerName/title 部分一致でフィルタされる', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(records: [
        buildRecord(electionId: 'e1', winnerName: '太郎', title: '村長選挙'),
        buildRecord(electionId: 'e2', winnerName: '花子', title: '町長選挙'),
      ]));

      await tester.enterText(
        find.byKey(AppKeys.manifestoSearchField),
        '花子',
      );
      await tester.pump();

      expect(find.byKey(AppKeys.manifestoRecordCard('e2')), findsOneWidget);
      expect(find.byKey(AppKeys.manifestoRecordCard('e1')), findsNothing);
      expect(find.byKey(AppKeys.manifestoListCount), findsOneWidget);
      expect(find.text('1件'), findsOneWidget);
    });

    testWidgets('検索クリア: クリアボタンで全件に戻る', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(records: [
        buildRecord(electionId: 'e1', winnerName: '太郎'),
        buildRecord(electionId: 'e2', winnerName: '花子'),
      ]));

      await tester.enterText(
        find.byKey(AppKeys.manifestoSearchField),
        '太郎',
      );
      await tester.pump();
      expect(find.byKey(AppKeys.manifestoRecordCard('e1')), findsOneWidget);
      expect(find.byKey(AppKeys.manifestoRecordCard('e2')), findsNothing);

      await tester.tap(find.byKey(AppKeys.manifestoSearchClear));
      await tester.pump();

      expect(find.byKey(AppKeys.manifestoRecordCard('e1')), findsOneWidget);
      expect(find.byKey(AppKeys.manifestoRecordCard('e2')), findsOneWidget);
    });
  });
}
