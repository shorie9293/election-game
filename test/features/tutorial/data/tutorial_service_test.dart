import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/features/tutorial/data/tutorial_service.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';
import 'package:election_game/features/game/domain/game_phase.dart';

void main() {
  group('TutorialService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('isFirstLaunch', () {
      test('初回起動はtrueを返す', () async {
        final result = await TutorialService.isFirstLaunch();
        expect(result, isTrue);
      });

      test('完了済みはfalseを返す', () async {
        await TutorialService.markCompleted();
        final result = await TutorialService.isFirstLaunch();
        expect(result, isFalse);
      });

      test('完了フラグを複数回マークしてもfalse', () async {
        await TutorialService.markCompleted();
        await TutorialService.markCompleted();
        final result = await TutorialService.isFirstLaunch();
        expect(result, isFalse);
      });
    });

    group('markCompleted', () {
      test('完了フラグが保存される', () async {
        expect(await TutorialService.isFirstLaunch(), isTrue);
        await TutorialService.markCompleted();
        expect(await TutorialService.isFirstLaunch(), isFalse);
      });
    });

    group('stepForPhase', () {
      test('citizenCreate → TutorialStep.citizenCreate', () {
        expect(
          TutorialService.stepForPhase(GamePhase.citizenCreate),
          TutorialStep.citizenCreate,
        );
      });

      test('home → TutorialStep.home', () {
        expect(
          TutorialService.stepForPhase(GamePhase.home),
          TutorialStep.home,
        );
      });

      test('electionAnnouncement → TutorialStep.home（homeと同じ）', () {
        expect(
          TutorialService.stepForPhase(GamePhase.electionAnnouncement),
          TutorialStep.home,
        );
      });

      test('debate → TutorialStep.debate', () {
        expect(
          TutorialService.stepForPhase(GamePhase.debate),
          TutorialStep.debate,
        );
      });

      test('vote → TutorialStep.vote', () {
        expect(
          TutorialService.stepForPhase(GamePhase.vote),
          TutorialStep.vote,
        );
      });

      test('result → TutorialStep.postElection', () {
        expect(
          TutorialService.stepForPhase(GamePhase.result),
          TutorialStep.postElection,
        );
      });

      test('ending → null（チュートリアルなし）', () {
        expect(
          TutorialService.stepForPhase(GamePhase.ending),
          isNull,
        );
      });
    });

    group('stepLabel', () {
      test('各ステップのラベルを返す', () {
        expect(TutorialService.stepLabel(TutorialStep.citizenCreate),
            'キャラクター作成');
        expect(TutorialService.stepLabel(TutorialStep.home), 'ホーム画面');
        expect(TutorialService.stepLabel(TutorialStep.townSquare), '街の広場');
        expect(TutorialService.stepLabel(TutorialStep.debate), '討論会');
        expect(TutorialService.stepLabel(TutorialStep.vote), '投票');
        expect(TutorialService.stepLabel(TutorialStep.postElection), '選挙後');
      });
    });

    group('stepDescription', () {
      test('各ステップの説明文を返す', () {
        expect(
          TutorialService.stepDescription(TutorialStep.citizenCreate),
          'まずは、あなたの職業を選びましょう。職業によって、政策への関心やNPCの反応が変わります。',
        );
        expect(
          TutorialService.stepDescription(TutorialStep.home),
          'ここがホーム画面です。生活パラメータを確認し、次の選挙に備えましょう。',
        );
        expect(
          TutorialService.stepDescription(TutorialStep.debate),
          '討論会です。候補者の主張を聞き、自分の考えを深めましょう。',
        );
        expect(
          TutorialService.stepDescription(TutorialStep.vote),
          'いよいよ投票です。あなたの一票が、天照町の未来を決めます。',
        );
        expect(
          TutorialService.stepDescription(TutorialStep.postElection),
          '選挙が終わりました。当選者の政策が町にどう影響するか、見守りましょう。',
        );
      });
    });
  });
}
