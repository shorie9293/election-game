import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';

void main() {
  group('TutorialStep enum', () {
    test('全てのステップが定義されている', () {
      expect(TutorialStep.values.length, 6);
      expect(TutorialStep.values, contains(TutorialStep.citizenCreate));
      expect(TutorialStep.values, contains(TutorialStep.home));
      expect(TutorialStep.values, contains(TutorialStep.townSquare));
      expect(TutorialStep.values, contains(TutorialStep.debate));
      expect(TutorialStep.values, contains(TutorialStep.vote));
      expect(TutorialStep.values, contains(TutorialStep.postElection));
    });

    group('label', () {
      test('citizenCreateのラベルが正しい', () {
        expect(TutorialStep.citizenCreate.label, 'キャラクター作成');
      });
      test('homeのラベルが正しい', () {
        expect(TutorialStep.home.label, 'ホーム画面');
      });
      test('townSquareのラベルが正しい', () {
        expect(TutorialStep.townSquare.label, '街の広場');
      });
      test('debateのラベルが正しい', () {
        expect(TutorialStep.debate.label, '討論会');
      });
      test('voteのラベルが正しい', () {
        expect(TutorialStep.vote.label, '投票');
      });
      test('postElectionのラベルが正しい', () {
        expect(TutorialStep.postElection.label, '選挙後');
      });
    });

    group('description', () {
      test('citizenCreateの説明文が正しい', () {
        expect(
          TutorialStep.citizenCreate.description,
          'まずは、あなたの職業を選びましょう。職業によって、政策への関心やNPCの反応が変わります。',
        );
      });
      test('homeの説明文が正しい', () {
        expect(
          TutorialStep.home.description,
          'ここがホーム画面です。生活パラメータを確認し、次の選挙に備えましょう。',
        );
      });
      test('townSquareの説明文が正しい', () {
        expect(
          TutorialStep.townSquare.description,
          contains('街の広場'),
        );
      });
      test('debateの説明文が正しい', () {
        expect(
          TutorialStep.debate.description,
          '討論会です。候補者の主張を聞き、自分の考えを深めましょう。',
        );
      });
      test('voteの説明文が正しい', () {
        expect(
          TutorialStep.vote.description,
          'いよいよ投票です。あなたの一票が、天照町の未来を決めます。',
        );
      });
      test('postElectionの説明文が正しい', () {
        expect(
          TutorialStep.postElection.description,
          '選挙が終わりました。当選者の政策が町にどう影響するか、見守りましょう。',
        );
      });
    });
  });
}
