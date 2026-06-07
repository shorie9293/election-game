import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/opposition_citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';

void main() {
  group('DialogTree', () {
    test('DialogTreeを生成できる', () {
      final tree = DialogTree(
        npcName: '五郎さん',
        greeting: 'おう、選挙の話か？',
        moodDialogs: {
          1: 'まあ誰でもいいよね…',
          3: '俺はA派だけどBの言い分もわかる',
          5: '……（何も言えない）',
        },
        debateReplies: {
          1: ['そうだね', 'うん、そうかも'],
          3: ['なるほど、一理ある', 'でも俺は違うと思う'],
        },
      );

      expect(tree.npcName, '五郎さん');
      expect(tree.greeting, 'おう、選挙の話か？');
      expect(tree.moodDialogs[1], 'まあ誰でもいいよね…');
    });

    test('getDialogForMood が適切なムード段階の台詞を返す', () {
      final tree = DialogTree(
        npcName: 'さくら',
        greeting: 'こんにちは',
        moodDialogs: {
          1: 'なれ合いの台詞',
          2: '融和の台詞',
          3: '健全な対立の台詞',
        },
        debateReplies: {},
      );

      expect(tree.getDialogForMood(0.0), 'なれ合いの台詞'); // stage 1
      expect(tree.getDialogForMood(0.25), '融和の台詞'); // stage 2
      expect(tree.getDialogForMood(0.5), '健全な対立の台詞'); // stage 3
      expect(tree.getDialogForMood(0.75), '健全な対立の台詞'); // stage 4 → fallback to 3
      expect(tree.getDialogForMood(1.0), '健全な対立の台詞'); // stage 5 → fallback to 3
    });

    test('getDebateReplies が適切なムード段階の返答を返す', () {
      final tree = DialogTree(
        npcName: '鉄也',
        greeting: 'やあ',
        moodDialogs: {},
        debateReplies: {
          2: ['そうですね', 'いい考えかも'],
          4: ['ふざけるな！', '何言ってるんだ！'],
        },
      );

      final replies = tree.getDebateReplies(0.3); // stage 2
      expect(replies, ['そうですね', 'いい考えかも']);

      // stage 5: no replies defined, falls back to stage 4
      expect(tree.getDebateReplies(0.9), ['ふざけるな！', '何言ってるんだ！']);
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final tree = DialogTree(
        npcName: '五郎',
        greeting: 'おう',
        moodDialogs: {1: '台詞1', 3: '台詞3'},
        debateReplies: {
          2: ['はい', 'いいえ'],
          4: ['反論1', '反論2'],
        },
      );

      final json = tree.toJson();
      final restored = DialogTree.fromJson(json);

      expect(restored.npcName, tree.npcName);
      expect(restored.greeting, tree.greeting);
      expect(restored.moodDialogs, tree.moodDialogs);
      expect(restored.debateReplies, tree.debateReplies);
    });

    test('copyWithで一部変更できる', () {
      final tree = DialogTree(
        npcName: '五郎',
        greeting: 'おう',
        moodDialogs: {1: '台詞'},
        debateReplies: {},
      );

      final updated = tree.copyWith(
        greeting: 'ども',
        moodDialogs: {2: '新しい台詞'},
      );

      expect(updated.greeting, 'ども');
      expect(updated.npcName, '五郎'); // unchanged
      expect(updated.moodDialogs, {2: '新しい台詞'});
    });

    test('getRelationshipGreeting 友好的(>0.5)でfriendly挨拶を返す', () {
      final tree = DialogTree(
        npcName: '五郎',
        greeting: 'おう',
        moodDialogs: {},
        debateReplies: {},
        relationshipGreetings: {
          'friendly': 'おっ、また来たのか！嬉しいよ',
          'neutral': 'やあ、調子はどうだい？',
          'hostile': '……何か用か',
        },
      );
      expect(tree.getRelationshipGreeting(0.7), 'おっ、また来たのか！嬉しいよ');
    });

    test('getRelationshipGreeting 敵対的(<-0.5)でhostile挨拶を返す', () {
      final tree = DialogTree(
        npcName: '鉄也',
        greeting: 'やあ',
        moodDialogs: {},
        debateReplies: {},
        relationshipGreetings: {
          'friendly': 'よお、元気か？',
          'hostile': '……お前か。話なら後にしてくれ',
        },
      );
      expect(tree.getRelationshipGreeting(-0.8), '……お前か。話なら後にしてくれ');
    });

    test('getRelationshipGreeting 中立(-0.5〜0.5)でneutral挨拶を返す', () {
      final tree = DialogTree(
        npcName: 'さくら',
        greeting: 'こんにちは',
        moodDialogs: {},
        debateReplies: {},
        relationshipGreetings: {
          'neutral': 'あら、こんにちは。選挙の話かしら',
        },
      );
      expect(tree.getRelationshipGreeting(0.2), 'あら、こんにちは。選挙の話かしら');
      expect(tree.getRelationshipGreeting(-0.3), 'あら、こんにちは。選挙の話かしら');
      expect(tree.getRelationshipGreeting(0.0), 'あら、こんにちは。選挙の話かしら');
    });

    test('getRelationshipGreeting 未設定キーはgreetingにフォールバック', () {
      final tree = DialogTree(
        npcName: 'ケン',
        greeting: 'よっ、元気？',
        moodDialogs: {},
        debateReplies: {},
        relationshipGreetings: {
          'friendly': 'おっ！久しぶり！',
        },
      );
      // hostile 未設定 → greeting にフォールバック
      expect(tree.getRelationshipGreeting(-0.7), 'よっ、元気？');
      // neutral 未設定 → greeting にフォールバック  
      expect(tree.getRelationshipGreeting(0.0), 'よっ、元気？');
    });

    test('relationshipGreetings が toJson/fromJson で保存される', () {
      final tree = DialogTree(
        npcName: 'おばあちゃん',
        greeting: 'おや、いらっしゃい',
        moodDialogs: {3: 'そうかい'},
        debateReplies: {3: ['あらまあ']},
        relationshipGreetings: {
          'friendly': 'まあまあ、よく来たねえ',
          'neutral': 'おや、どちらさんかね',
          'hostile': '……あんたにはがっかりだよ',
        },
      );
      final json = tree.toJson();
      final restored = DialogTree.fromJson(json);
      expect(restored.relationshipGreetings['friendly'], 'まあまあ、よく来たねえ');
      expect(restored.relationshipGreetings['neutral'], 'おや、どちらさんかね');
      expect(restored.relationshipGreetings['hostile'], '……あんたにはがっかりだよ');
    });
  });

  group('OppositionCitizen', () {
    test('OppositionCitizenを生成できる', () {
      final dialogTree = DialogTree(
        npcName: '五郎さん',
        greeting: 'おう、選挙の話か？',
        moodDialogs: {
          1: 'まあ誰でもいいよね…',
          3: '俺はA派だけどBの言い分もわかる',
        },
        debateReplies: {
          3: ['なるほど', 'でも俺は違うと思う'],
        },
      );

      final npc = OppositionCitizen(
        id: 'npc_goro',
        name: '五郎さん',
        job: Job.farmer,
        personality: '頑固だが筋は通す',
        supportedCandidateId: 'candidate_3',
        stubbornness: 0.8,
        debateTopics: [Concern.agriculture, Concern.environment, Concern.tax],
        dialogs: dialogTree,
      );

      expect(npc.id, 'npc_goro');
      expect(npc.name, '五郎さん');
      expect(npc.job, Job.farmer);
      expect(npc.personality, '頑固だが筋は通す');
      expect(npc.supportedCandidateId, 'candidate_3');
      expect(npc.stubbornness, 0.8);
      expect(npc.debateTopics, [Concern.agriculture, Concern.environment, Concern.tax]);
      expect(npc.dialogs.npcName, '五郎さん');
    });

    test('samplesで5人の対立市民が生成される', () {
      final npcs = OppositionCitizen.samples();

      expect(npcs.length, 5);
      expect(npcs.map((n) => n.name), containsAll([
        '五郎さん',
        'さくら',
        '鉄也',
        'おばあちゃん',
        '若者ケン',
      ]));
    });

    test('サンプルの各NPCが有効な値を持つ', () {
      for (final npc in OppositionCitizen.samples()) {
        expect(npc.id, isNotEmpty);
        expect(npc.name, isNotEmpty);
        expect(npc.personality, isNotEmpty);
        expect(npc.stubbornness, inInclusiveRange(0.0, 1.0));
        expect(npc.debateTopics, isNotEmpty);
        expect(npc.dialogs.greeting, isNotEmpty);
        expect(npc.dialogs.moodDialogs, isNotEmpty);
      }
    });

    test('stubbornnessが範囲外ならアサーションエラー', () {
      expect(
        () => OppositionCitizen(
          id: 'test',
          name: 'test',
          job: Job.farmer,
          personality: 'test',
          stubbornness: 1.5,
          debateTopics: [],
          dialogs: DialogTree(npcName: 't', greeting: 'g', moodDialogs: {}, debateReplies: {}),
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => OppositionCitizen(
          id: 'test',
          name: 'test',
          job: Job.farmer,
          personality: 'test',
          stubbornness: -0.1,
          debateTopics: [],
          dialogs: DialogTree(npcName: 't', greeting: 'g', moodDialogs: {}, debateReplies: {}),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('changeSupport で支持候補を変更できる', () {
      final npc = OppositionCitizen.samples().first;
      final updated = npc.changeSupport('candidate_new');

      expect(updated.supportedCandidateId, 'candidate_new');
      expect(npc.supportedCandidateId, isNot('candidate_new')); // immutable
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final npc = OppositionCitizen(
        id: 'npc_test',
        name: 'テスト太郎',
        job: Job.teacher,
        personality: '理知的',
        supportedCandidateId: 'candidate_2',
        stubbornness: 0.3,
        debateTopics: [Concern.education, Concern.healthcare],
        dialogs: DialogTree(
          npcName: 'テスト太郎',
          greeting: 'こんにちは',
          moodDialogs: {3: '議論しよう'},
          debateReplies: {3: ['賛成', '反対']},
        ),
      );

      final json = npc.toJson();
      final restored = OppositionCitizen.fromJson(json);

      expect(restored.id, npc.id);
      expect(restored.name, npc.name);
      expect(restored.job, npc.job);
      expect(restored.personality, npc.personality);
      expect(restored.supportedCandidateId, npc.supportedCandidateId);
      expect(restored.stubbornness, npc.stubbornness);
      expect(restored.debateTopics, npc.debateTopics);
      expect(restored.dialogs.npcName, npc.dialogs.npcName);
    });

    test('copyWithで一部変更できる', () {
      final npc = OppositionCitizen.samples().first;
      final updated = npc.copyWith(
        stubbornness: 0.5,
        supportedCandidateId: 'candidate_other',
      );

      expect(updated.stubbornness, 0.5);
      expect(updated.supportedCandidateId, 'candidate_other');
      expect(updated.name, npc.name); // unchanged
    });

    test('equatableで等価性が正しい', () {
      final tree = DialogTree(
        npcName: 'A', greeting: 'hi', moodDialogs: {}, debateReplies: {},
      );
      final a = OppositionCitizen(
        id: '1', name: 'A', job: Job.farmer, personality: 'p',
        stubbornness: 0.5, debateTopics: [], dialogs: tree,
      );
      final b = OppositionCitizen(
        id: '1', name: 'A', job: Job.farmer, personality: 'p',
        stubbornness: 0.5, debateTopics: [], dialogs: tree,
      );
      final c = OppositionCitizen(
        id: '2', name: 'A', job: Job.farmer, personality: 'p',
        stubbornness: 0.5, debateTopics: [], dialogs: tree,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
