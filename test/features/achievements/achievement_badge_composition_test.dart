import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/quiz_result.dart';
import 'package:election_game/features/achievements/domain/achievement_badge.dart';
import 'package:election_game/features/achievements/domain/achievement_badge_service.dart';
import 'package:election_game/features/achievements/presentation/achievement_badge_screen.dart';
import 'package:election_game/screens/game_screen.dart';

/// 親探針：眷属の個別試練では撃たれない「合成の不変条件」を撃つ。
///
/// 1) GameScreen → ホームの導線 → 実績画面 が実データで繋がること
/// 2) 画面の表示値がサービスの独立集計と一致すること
/// 3) 未獲得バッジも条件つきで全件提示されること（獲得＋未獲得＝定義数）
void main() {
  group('実績バッジ 合成探針', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'election_game_tutorial_completed': true,
      });
    });

    Future<void> pumpAchievements(
      WidgetTester tester, {
      int electionCount = 0,
      ElectionScale scale = ElectionScale.village,
      QuizBestScore? quizBest,
    }) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementBadgeScreen(
            electionCount: electionCount,
            scale: scale,
            quizBestOverride: quizBest,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('GameScreen: ホームの実績ボタンが実データで実績画面へ繋がる', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: GameScreen()));
      await tester.pumpAndSettle();

      // キャラメイク → ホーム
      await tester.enterText(find.byKey(AppKeys.citizenNameInput), 'テスト');
      await tester.tap(find.byKey(AppKeys.citizenCreateButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.homeTitle), findsOneWidget);

      // ホームの実績バッジ導線
      expect(find.byKey(AppKeys.homeAchievementsButton), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.homeAchievementsButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.achievementScreen), findsOneWidget);

      // 選挙未経験の初期状態 → サービスの独立集計と一致するはず
      final expected =
          AchievementBadgeService.collect(const AchievementSignals());
      expect(expected.summaryLabel, '獲得 0 / 14');
      expect(find.text(expected.summaryLabel), findsOneWidget);
    });

    testWidgets('画面の獲得数はサービスの独立集計と一致する（部分達成）', (tester) async {
      const quizBest = QuizBestScore(correctCount: 3, total: 5, attempts: 1);
      final expected = AchievementBadgeService.collect(
        const AchievementSignals(
          electionCount: 3,
          scale: ElectionScale.town,
          quizBest: quizBest,
        ),
      );

      await pumpAchievements(
        tester,
        electionCount: 3,
        scale: ElectionScale.town,
        quizBest: quizBest,
      );

      // first_election(1) / election_3(3) / town_reached(1) / quiz_first(1) / quiz_correct_3(3)
      expect(expected.earnedCount, 5);
      expect(find.text(expected.summaryLabel), findsOneWidget);
      expect(find.text('獲得 5 / 14'), findsOneWidget);
    });

    testWidgets('未獲得バッジも条件つきで全件提示される（獲得＋未獲得＝定義数）', (tester) async {
      await pumpAchievements(tester);

      // 全定義の行が描画される
      for (final d in AchievementBadgeService.definitions) {
        expect(
          find.byKey(AppKeys.achievementBadgeRow(d.id)),
          findsOneWidget,
          reason: 'バッジ ${d.id} の行が提示されていない',
        );
      }
      // 獲得アイコン＋ロックアイコンの総和が定義数と一致
      final earned = find.byIcon(Icons.emoji_events).evaluate().length;
      final locked = find.byIcon(Icons.lock_outline).evaluate().length;
      expect(earned + locked, AchievementBadgeService.definitions.length);
    });
  });
}
