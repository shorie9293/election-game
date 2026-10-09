import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/repositories/life_param_snapshot_repository.dart';
import 'package:election_game/domain/repositories/manifesto_repository.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/features/lifetrend/presentation/life_param_trend_screen.dart';
import 'package:election_game/screens/game_screen.dart';

void main() {
  group('生活パラメータ推移 導線', () {
    testWidgets('ホーム AppBar に推移ボタンが表示され、押すと画面遷移する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => HomeScreen(
              citizen: Citizen.initial(Job.farmer).copyWith(name: 'テスト'),
              societyState: SocietyState.initial(),
              remainingTurns: 5,
              onOpenLifeParamTrend: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LifeParamTrendScreen(
                      key: AppKeys.lifeParamTrendScreen,
                      snapshotsOverride: const [],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(AppKeys.homeLifeParamTrendButton), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.homeLifeParamTrendButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.lifeParamTrendScreen), findsOneWidget);
    });

    testWidgets('選挙完了→Continue でスナップショットがリポジトリに記録される', (tester) async {
      final lifeParamRepository = InMemoryLifeParamSnapshotRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            archiveRepository: InMemoryElectionArchiveRepository(),
            manifestoRepository: InMemoryManifestoRepository(),
            lifeParamSnapshotRepository: lifeParamRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. キャラメイク
      await tester.enterText(
        find.byKey(AppKeys.citizenNameInput),
        'タロウ',
      );
      await tester.tap(find.byKey(AppKeys.citizenCreateButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.homeTitle), findsOneWidget);

      // 2. 選挙へ
      await tester.scrollUntilVisible(
        find.byKey(AppKeys.homeElectionButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(AppKeys.homeElectionButton));
      await tester.pumpAndSettle();

      // 3. 討論会へ
      await tester.tap(find.byKey(AppKeys.electionProceedButton));
      await tester.pumpAndSettle();

      // 4. 討論会を進める（2候補者×2発言）
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(AppKeys.debateReactionSilent));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.descendant(
        of: find.byKey(AppKeys.debateRatingStars('candidate_1')),
        matching: find.byIcon(Icons.star_border),
      ).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byKey(AppKeys.debateRatingStars('candidate_2')),
        matching: find.byIcon(Icons.star_border),
      ).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.debateRatingSubmit));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.debateToVoteButton));
      await tester.pumpAndSettle();

      // 5. 投票
      await tester.tap(find.text('山田太郎').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.voteConfirmButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.resultTitle), findsOneWidget);

      // 6. Continue → ホームに戻る
      await tester.scrollUntilVisible(
        find.byKey(AppKeys.resultContinueButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(AppKeys.resultContinueButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.homeTitle), findsOneWidget);

      // 7. スナップショットが1件記録されている
      final snapshots = await lifeParamRepository.load();
      expect(snapshots, hasLength(1));
      expect(snapshots.single.values, isNotEmpty);
    });
  });
}