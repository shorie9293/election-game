import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/core/sound/sound_settings.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/screens/game_screen.dart';
import 'package:election_game/services/bgm_service.dart';
import 'package:election_game/services/sfx_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'election_game_tutorial_completed': true,
    });
  });

  group('Sound settings wiring (GameScreen)', () {
    testWidgets('(a) bgmEnabled=false で起動→BGM play は呼ばれない（stop が呼ばれる）',
        (tester) async {
      final bgm = MockBgmService();
      final sfx = MockSfxService();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            soundSettings: const SoundSettings(bgmEnabled: false),
            bgmService: bgm,
            sfxService: sfx,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(bgm.playCount, 0);
      expect(bgm.stopCount, greaterThanOrEqualTo(1));
    });

    testWidgets('(b) bgmEnabled=true・volume=0.2 で起動→play が呼ばれ setVolume(0.2)',
        (tester) async {
      final bgm = MockBgmService();
      final sfx = MockSfxService();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            soundSettings: const SoundSettings(bgmEnabled: true, volume: 0.2),
            bgmService: bgm,
            sfxService: sfx,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(bgm.playCount, greaterThanOrEqualTo(1));
      expect(bgm.volume, 0.2);
    });

    testWidgets(
        '(c) 同一 key で再構築: ON→OFF で stop が増え、OFF→ON で play が増える',
        (tester) async {
      final bgm = MockBgmService();
      final sfx = MockSfxService();
      final gameKey = GlobalKey();

      Future<void> rebuild(SoundSettings settings) async {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: gameKey,
              soundSettings: settings,
              bgmService: bgm,
              sfxService: sfx,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await rebuild(const SoundSettings(bgmEnabled: true, volume: 0.5));
      final playsAfterOn = bgm.playCount;
      final stopsBeforeOff = bgm.stopCount;

      // 同じ GameScreen State（key 同一）を新設定で再構築 → OFF
      await rebuild(const SoundSettings(bgmEnabled: false, volume: 0.5));
      expect(bgm.stopCount, greaterThan(stopsBeforeOff));

      // ON に戻す → play が増える
      await rebuild(const SoundSettings(bgmEnabled: true, volume: 0.5));
      expect(bgm.playCount, greaterThan(playsAfterOn));

      // 音量のみ変更 → setVolume が伝わる
      await rebuild(const SoundSettings(bgmEnabled: true, volume: 0.9));
      expect(bgm.volume, 0.9);
    });

    testWidgets('(d) sfxEnabled=false なら投票経路で voteCount==0、true なら 1',
        (tester) async {
      Future<void> runCase({required bool sfxEnabled}) async {
        final bgm = MockBgmService();
        final sfx = MockSfxService();
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: ValueKey('game_sfx_$sfxEnabled'),
              soundSettings: SoundSettings(
                bgmEnabled: false,
                sfxEnabled: sfxEnabled,
              ),
              bgmService: bgm,
              sfxService: sfx,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // キャラメイク
        await tester.enterText(
          find.byKey(AppKeys.citizenNameInput),
          'サウンド市民',
        );
        await tester.tap(find.byKey(AppKeys.citizenCreateButton));
        await tester.pumpAndSettle();

        // 選挙へ
        await tester.scrollUntilVisible(
          find.byKey(AppKeys.homeElectionButton),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(AppKeys.homeElectionButton));
        await tester.pumpAndSettle();

        // 討論会へ
        await tester.tap(find.byKey(AppKeys.electionProceedButton));
        await tester.pumpAndSettle();

        // 討論を進める（2候補×2発言=4）
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.byKey(AppKeys.debateReactionSilent));
          await tester.pumpAndSettle();
        }
        // 評価
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

        // 投票画面へ
        await tester.tap(find.byKey(AppKeys.debateToVoteButton));
        await tester.pumpAndSettle();
        expect(find.byKey(AppKeys.voteTitle), findsOneWidget);

        // 投票確定
        await tester.tap(find.text('山田太郎').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(AppKeys.voteConfirmButton));
        await tester.pumpAndSettle();

        expect(sfx.voteCount, sfxEnabled ? 1 : 0);
      }

      await runCase(sfxEnabled: false);
      // 新しいウィジェットツリーで true のケースを実行
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await runCase(sfxEnabled: true);
    });
  });
}
