import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/sound/sound_settings.dart';
import 'package:election_game/core/sound/sound_settings_repository.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/features/settings/presentation/sound_settings_screen.dart';
import 'package:election_game/screens/game_screen.dart';
import 'package:election_game/services/bgm_service.dart';
import 'package:election_game/services/sfx_service.dart';

/// 親（イシコリ）の探針 — 合成の不変条件を撃つ。
///
/// 眷属は画面単体・サービス単体を検証しがちで、
/// 「画面 tap → 状態 → 永続化」「導線 → 画面 → コールバック」「再開時の音量適用」
/// 「棄権経路の効果音」は誰も撃たない。ここでそれを撃つ。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'election_game_tutorial_completed': true,
    });
  });

  group('親探針A: 画面 tap → 状態 → 永続化の合成', () {
    testWidgets('BGMスイッチを切り、リポジトリで保存→読み直しで復元される',
        (tester) async {
      // 画面の onChanged を受けて保存するだけの薄い親（main.dart と同じ合成）
      var current = const SoundSettings(
        bgmEnabled: true,
        sfxEnabled: true,
        volume: 0.4,
      );
      const repo = SoundSettingsRepository();
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return SoundSettingsScreen(
                currentSettings: current,
                onChanged: (next) async {
                  await repo.save(next);
                  setState(() => current = next);
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.soundBgmSwitch));
      await tester.pumpAndSettle();

      // 3キーが個別に保存されている（実キー名で確認）
      expect(prefs.getBool(SoundSettings.bgmStorageKey), isFalse);
      expect(prefs.getBool(SoundSettings.sfxStorageKey), isTrue);
      expect(prefs.getDouble(SoundSettings.volumeStorageKey), 0.4);

      // 読み直すと画面で消した BGM がオフのまま復元される
      final reloaded = await repo.load();
      expect(reloaded.bgmEnabled, isFalse);
      expect(reloaded.sfxEnabled, isTrue);
      expect(reloaded.volume, 0.4);
    });

    testWidgets('音量スライダーを操作すると他フィールドを壊さず保存される', (tester) async {
      SoundSettings? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: SoundSettingsScreen(
            currentSettings: const SoundSettings(
              bgmEnabled: true,
              sfxEnabled: false,
              volume: 0.8,
            ),
            onChanged: (next) => reported = next,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(AppKeys.soundVolumeSlider),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.volume, lessThan(0.8));
      expect(reported!.bgmEnabled, isTrue);
      expect(reported!.sfxEnabled, isFalse);
    });
  });

  group('親探針B: HomeScreen 導線 → 画面 → コールバックの合成', () {
    testWidgets('AppBar のサウンド導線から設定画面が開き、変更が親へ伝わる',
        (tester) async {
      SoundSettings? received;
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer),
            societyState: SocietyState.initial(),
            remainingTurns: 10,
            soundSettings: const SoundSettings(volume: 0.6),
            onSoundSettingsChanged: (s) => received = s,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.soundSettingsEntry));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.soundSettingsScreen), findsOneWidget);
      // 導線が現在値を渡している（既定値に化けていない）
      final screen = tester.widget<SoundSettingsScreen>(
        find.byType(SoundSettingsScreen),
      );
      expect(screen.currentSettings.volume, 0.6);

      await tester.tap(find.byKey(AppKeys.soundSfxSwitch));
      await tester.pumpAndSettle();

      expect(received, isNotNull);
      expect(received!.sfxEnabled, isFalse);
      expect(received!.volume, 0.6);
    });
  });

  group('親探針C: BGM 再開時の音量適用の不変条件', () {
    testWidgets('BGMオフ中に音量を変えても、再開時に新しい音量が適用される', (tester) async {
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

      // オフ起動: 音量は適用されない（既定の 1.0 のまま）
      await rebuild(
        const SoundSettings(bgmEnabled: false, volume: 0.3),
      );
      expect(bgm.playCount, 0);
      expect(bgm.volume, 1.0);

      // オフのまま音量だけ変更 → 再生していないので setVolume は走らない
      await rebuild(
        const SoundSettings(bgmEnabled: false, volume: 0.9),
      );
      expect(bgm.volume, 1.0);

      // 再開 → 再開時点の音量 0.9 が必ず適用される（古い音量で鳴り出さない）
      await rebuild(
        const SoundSettings(bgmEnabled: true, volume: 0.9),
      );
      expect(bgm.playCount, greaterThanOrEqualTo(1));
      expect(bgm.volume, 0.9);
    });
  });

  group('親探針D: 効果音は棄権経路でも設定に従う', () {
    Future<void> navigateToVote(WidgetTester tester, MockSfxService sfx,
        {required bool sfxEnabled}) async {
      final bgm = MockBgmService();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            key: ValueKey('probe_abstain_$sfxEnabled'),
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

      await tester.enterText(
        find.byKey(AppKeys.citizenNameInput),
        '棄権市民',
      );
      await tester.tap(find.byKey(AppKeys.citizenCreateButton));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(AppKeys.homeElectionButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(AppKeys.homeElectionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.electionProceedButton));
      await tester.pumpAndSettle();

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
      expect(find.byKey(AppKeys.voteTitle), findsOneWidget);
    }

    testWidgets('sfxEnabled=true なら棄権で playAbstain が1回だけ呼ばれる', (tester) async {
      final sfx = MockSfxService();
      await navigateToVote(tester, sfx, sfxEnabled: true);

      await tester.tap(find.byKey(AppKeys.voteAbstainButton));
      await tester.pumpAndSettle();

      expect(sfx.abstainCount, 1);
      expect(sfx.voteCount, 0);
    });

    testWidgets('sfxEnabled=false なら棄権でも効果音は鳴らない', (tester) async {
      final sfx = MockSfxService();
      await navigateToVote(tester, sfx, sfxEnabled: false);

      await tester.tap(find.byKey(AppKeys.voteAbstainButton));
      await tester.pumpAndSettle();

      expect(sfx.abstainCount, 0);
      expect(sfx.voteCount, 0);
    });
  });
}
