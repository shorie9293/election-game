import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/quiz_result.dart';
import 'package:election_game/features/achievements/domain/achievement_badge.dart';
import 'package:election_game/features/achievements/presentation/achievement_badge_screen.dart';

Election _election({
  required DateTime local,
  String? winnerId,
  String? voterId,
}) {
  final millis = local.toUtc().millisecondsSinceEpoch;
  return Election(
    id: 'election_$millis',
    title: 'テスト選挙',
    scale: ElectionScale.town,
    candidates: const [],
    winnerId: winnerId,
    voteCounts: winnerId == null ? null : const {'a': 1},
    voterId: voterId,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  int electionCount = 0,
  ElectionScale scale = ElectionScale.village,
  List<Election> pastElections = const [],
  QuizBestScore? quizBest,
}) async {
  // tier セクションが4つ縦に並ぶため、既定ビューポートでは下方が遅延描画される
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: AchievementBadgeScreen(
        electionCount: electionCount,
        scale: scale,
        pastElections: pastElections,
        quizBestOverride: quizBest,
      ),
    ),
  );
  // 読込中の不確定インジケータは pumpAndSettle を永久に止めるため pump で進める
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    // quizBestOverride を渡さない試練でも Repository が実 I/O へ落ちないようにする
    SharedPreferences.setMockInitialValues({});
  });

  group('AchievementBadgeScreen', () {
    testWidgets('画面が描画され、全バッジの行が並ぶ', (tester) async {
      await _pump(tester);

      expect(find.byKey(AppKeys.achievementScreen), findsOneWidget);
      expect(find.byKey(AppKeys.achievementSummary), findsOneWidget);
      expect(find.byKey(AppKeys.achievementList), findsOneWidget);

      for (final t in BadgeTier.values) {
        expect(
          find.byKey(AppKeys.achievementTierSection(t.name)),
          findsOneWidget,
        );
      }
    });

    testWidgets('記録なしは獲得 0 / 14 と表示され、全行が未獲得（ロック）', (tester) async {
      await _pump(tester);

      expect(find.text('獲得 0 / 14'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(14));
      expect(find.byIcon(Icons.emoji_events), findsNothing);
    });

    testWidgets('達成済みシグナルでは獲得数と行の表示が一致する', (tester) async {
      await _pump(
        tester,
        electionCount: 3,
        scale: ElectionScale.town,
        pastElections: [
          _election(
            local: DateTime(2026, 10, 11, 9),
            winnerId: 'a',
            voterId: 'a',
          ),
        ],
        quizBest: const QuizBestScore(correctCount: 3, total: 5, attempts: 1),
      );

      expect(find.text('獲得 6 / 14'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsNWidgets(6));
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(8));
    });

    testWidgets('行の進捗表示は current / required で、required を超えない', (tester) async {
      await _pump(tester, electionCount: 4, quizBest: const QuizBestScore(
        correctCount: 1,
        total: 5,
        attempts: 1,
      ));

      // electionCount=4 → election_3 は '3 / 3'（超過表示しない）
      expect(
        find.descendant(
          of: find.byKey(AppKeys.achievementBadgeRow('election_3')),
          matching: find.text('3 / 3'),
        ),
        findsOneWidget,
      );
      // election_5 は '4 / 5'
      expect(
        find.descendant(
          of: find.byKey(AppKeys.achievementBadgeRow('election_5')),
          matching: find.text('4 / 5'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('バッジ名と説明が画面に現れる', (tester) async {
      await _pump(tester);

      expect(find.text('初陣'), findsOneWidget);
      expect(find.text('選挙の申し子'), findsOneWidget);
      expect(find.text('選挙マスター'), findsOneWidget);
    });
  });
}
