import 'package:equatable/equatable.dart';
import 'citizen_enums.dart';

/// 対立市民の会話ツリー
///
/// 社会ムード（なれ合い1〜独裁5）に応じて異なる台詞を返す。
/// さらにプレイヤーとの関係値に応じて挨拶が変化する。
class DialogTree extends Equatable {
  final String npcName;
  final String greeting;
  final Map<int, String> moodDialogs;
  final Map<int, List<String>> debateReplies;

  /// 関係値に応じた挨拶（いずれもオプション。未指定時はgreetingにフォールバック）
  /// "friendly": 関係値 > 0.5, "neutral": -0.5〜0.5, "hostile": < -0.5
  final Map<String, String> relationshipGreetings;

  const DialogTree({
    required this.npcName,
    required this.greeting,
    required this.moodDialogs,
    required this.debateReplies,
    this.relationshipGreetings = const {},
  });

  /// 社会ムード値（0.0〜1.0）から適切な台詞を取得
  String getDialogForMood(double mood) {
    final stage = _moodToStage(mood);
    if (moodDialogs.containsKey(stage)) {
      return moodDialogs[stage]!;
    }
    // 近い段階を探索（降順）
    for (int s = stage; s >= 1; s--) {
      if (moodDialogs.containsKey(s)) {
        return moodDialogs[s]!;
      }
    }
    return greeting;
  }

  /// 社会ムード値から討論時の返答リストを取得
  List<String> getDebateReplies(double mood) {
    final stage = _moodToStage(mood);
    if (debateReplies.containsKey(stage)) {
      return debateReplies[stage]!;
    }
    // 近い段階を探索（降順）
    for (int s = stage; s >= 1; s--) {
      if (debateReplies.containsKey(s)) {
        return debateReplies[s]!;
      }
    }
    return const [];
  }

  /// mood値（0.0〜1.0）を5段階（1〜5）に変換
  static int _moodToStage(double mood) {
    if (mood < 0.2) return 1; // なれ合い
    if (mood < 0.4) return 2; // 融和
    if (mood < 0.6) return 3; // 健全な対立
    if (mood < 0.8) return 4; // 不健全な対立
    return 5; // 独裁
  }

  /// 関係値に応じた挨拶を返す
  ///
  /// [relationship] が 0.5 超なら friendly、-0.5 未満なら hostile の挨拶を返す。
  /// それ以外は neutral。未設定のキーは greeting にフォールバックする。
  String getRelationshipGreeting(double relationship) {
    if (relationship > 0.5) {
      return relationshipGreetings['friendly'] ?? greeting;
    }
    if (relationship < -0.5) {
      return relationshipGreetings['hostile'] ?? greeting;
    }
    return relationshipGreetings['neutral'] ?? greeting;
  }

  DialogTree copyWith({
    String? npcName,
    String? greeting,
    Map<int, String>? moodDialogs,
    Map<int, List<String>>? debateReplies,
    Map<String, String>? relationshipGreetings,
  }) {
    return DialogTree(
      npcName: npcName ?? this.npcName,
      greeting: greeting ?? this.greeting,
      moodDialogs: moodDialogs ?? this.moodDialogs,
      debateReplies: debateReplies ?? this.debateReplies,
      relationshipGreetings:
          relationshipGreetings ?? this.relationshipGreetings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'npcName': npcName,
      'greeting': greeting,
      'moodDialogs':
          moodDialogs.map((k, v) => MapEntry(k.toString(), v)),
      'debateReplies': debateReplies.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'relationshipGreetings': relationshipGreetings,
    };
  }

  factory DialogTree.fromJson(Map<String, dynamic> json) {
    return DialogTree(
      npcName: json['npcName'] as String,
      greeting: json['greeting'] as String,
      moodDialogs: (json['moodDialogs'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as String),
      ),
      debateReplies: (json['debateReplies'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), (v as List).cast<String>()),
      ),
      relationshipGreetings: json['relationshipGreetings'] != null
          ? Map<String, String>.from(
              json['relationshipGreetings'] as Map)
          : {},
    );
  }

  @override
  List<Object?> get props => [
        npcName,
        greeting,
        moodDialogs,
        debateReplies,
        relationshipGreetings,
      ];
}

/// 対立市民（NPC）モデル
///
/// プレイヤーが街で出会い、選挙について議論できる市民NPC。
/// 社会ムードに応じて台詞が変化し、議論によって支持候補が変わりうる。
class OppositionCitizen extends Equatable {
  final String id;
  final String name;
  final Job job;
  final String personality;
  final String? supportedCandidateId;
  final double stubbornness; // 0.0〜1.0
  final List<Concern> debateTopics;
  final DialogTree dialogs;

  const OppositionCitizen({
    required this.id,
    required this.name,
    required this.job,
    required this.personality,
    this.supportedCandidateId,
    required this.stubbornness,
    required this.debateTopics,
    required this.dialogs,
  }) : assert(stubbornness >= 0.0 && stubbornness <= 1.0,
             'stubbornnessは0.0〜1.0の範囲である必要があります');

  /// 支持候補を変更する（immutable）
  OppositionCitizen changeSupport(String? candidateId) {
    return copyWith(supportedCandidateId: candidateId);
  }

  OppositionCitizen copyWith({
    String? id,
    String? name,
    Job? job,
    String? personality,
    String? supportedCandidateId,
    double? stubbornness,
    List<Concern>? debateTopics,
    DialogTree? dialogs,
  }) {
    return OppositionCitizen(
      id: id ?? this.id,
      name: name ?? this.name,
      job: job ?? this.job,
      personality: personality ?? this.personality,
      supportedCandidateId:
          supportedCandidateId ?? this.supportedCandidateId,
      stubbornness: stubbornness ?? this.stubbornness,
      debateTopics: debateTopics ?? this.debateTopics,
      dialogs: dialogs ?? this.dialogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'job': job.name,
      'personality': personality,
      'supportedCandidateId': supportedCandidateId,
      'stubbornness': stubbornness,
      'debateTopics': debateTopics.map((c) => c.name).toList(),
      'dialogs': dialogs.toJson(),
    };
  }

  factory OppositionCitizen.fromJson(Map<String, dynamic> json) {
    return OppositionCitizen(
      id: json['id'] as String,
      name: json['name'] as String,
      job: Job.values.firstWhere((j) => j.name == json['job']),
      personality: json['personality'] as String,
      supportedCandidateId: json['supportedCandidateId'] as String?,
      stubbornness: (json['stubbornness'] as num).toDouble(),
      debateTopics: (json['debateTopics'] as List)
          .map((c) => Concern.values.firstWhere((x) => x.name == c))
          .toList(),
      dialogs: DialogTree.fromJson(json['dialogs'] as Map<String, dynamic>),
    );
  }

  /// 神想書準拠の5人のサンプル対立市民
  static List<OppositionCitizen> samples() {
    return [
      // 五郎さん — 農家、頑固、守りの会支持
      OppositionCitizen(
        id: 'npc_goro',
        name: '五郎さん',
        job: Job.farmer,
        personality: '頑固だが筋は通す',
        supportedCandidateId: 'candidate_3',
        stubbornness: 0.8,
        debateTopics: [Concern.agriculture, Concern.environment, Concern.tax],
        dialogs: DialogTree(
          npcName: '五郎さん',
          greeting: 'おう、若いのも選挙の話か？',
          moodDialogs: {
            1: 'まあ誰がなっても同じだべ。今年も豊作ならそれでいい。',
            2: 'AさんもBさんも悪くないけどな。迷うべ。',
            3: '俺は守りの会の〇〇を推す。お前は誰に入れる？',
            4: '発展の会は農家のことをわかってねえ！税金ばかり上げやがって！',
            5: '……（怖くて誰のことも言えない）',
          },
          debateReplies: {
            2: ['そうだな、お前の言う通りかもな', 'ふむ、一理ある'],
            3: ['なるほど、そういう考え方もあるか', 'いや、俺は違うと思うぞ'],
            4: ['それは違うべ！', '話にならんな…'],
          },
        ),
      ),
      // さくら — 教師、理知的、共生の会支持
      OppositionCitizen(
        id: 'npc_sakura',
        name: 'さくら',
        job: Job.teacher,
        personality: '理知的で開かれている',
        supportedCandidateId: 'candidate_2',
        stubbornness: 0.3,
        debateTopics: [Concern.education, Concern.healthcare, Concern.economy],
        dialogs: DialogTree(
          npcName: 'さくら',
          greeting: 'こんにちは。選挙についてお話ししますか？',
          moodDialogs: {
            1: '今回は候補者がお一方だけですね。少し寂しいです。',
            2: '共生の会の政策は教育に力を入れていて好感が持てます。',
            3: 'それぞれの候補に良さがありますね。じっくり考えたいです。',
            4: '感情的にならず、政策の中身で判断しましょう。',
            5: '（小声で）これ以上は…申し訳ありません。',
          },
          debateReplies: {
            2: ['素敵な視点ですね', '私もそう思います'],
            3: ['なるほど、その考えは新鮮です', '違う角度から考えると…'],
            4: ['冷静に話し合いましょう', '人格ではなく政策を見ましょう'],
          },
        ),
      ),
      // 鉄也 — 商人、打算的、発展の会支持
      OppositionCitizen(
        id: 'npc_tetsuya',
        name: '鉄也',
        job: Job.merchant,
        personality: '打算的、実利重視',
        supportedCandidateId: 'candidate_1',
        stubbornness: 0.6,
        debateTopics: [Concern.economy, Concern.tax, Concern.employment],
        dialogs: DialogTree(
          npcName: '鉄也',
          greeting: 'やあ、景気の話かい？',
          moodDialogs: {
            1: 'ま、誰がやっても商売は変わらんよ。',
            2: '発展の会の減税案は悪くないね。でも共生の会の福祉も気になる。',
            3: '俺は発展の会だ。経済が回らなきゃ福祉もクソもないからな！',
            4: '共生の会は金をばらまくだけだ！働かざる者食うべからず！',
            5: '（小声で）発展の会以外に入れるのは損だぞ…',
          },
          debateReplies: {
            2: ['それも商売になるかもね', 'うーん、コストが…'],
            3: ['数字で示せるかい？', '理屈はわかるが現実はな…'],
            4: ['ふざけるな！', '何言ってるんだ！'],
          },
        ),
      ),
      // おばあちゃん — 無職、伝統重視、守りの会支持
      OppositionCitizen(
        id: 'npc_granny',
        name: 'おばあちゃん',
        job: Job.unemployed,
        personality: '伝統を重んじる',
        supportedCandidateId: 'candidate_3',
        stubbornness: 0.9,
        debateTopics: [Concern.safety, Concern.healthcare, Concern.education],
        dialogs: DialogTree(
          npcName: 'おばあちゃん',
          greeting: 'あら、あんたも投票に行くのかい？えらいねえ。',
          moodDialogs: {
            1: '昔はみんなもっと真面目に選挙に行ったもんさ。',
            2: '若い人が政治に関心を持つのはいいことだねえ。',
            3: '私は守りの会を応援してるよ。伝統を大事にしてくれるからね。',
            4: '最近の若いもんは伝統を軽んじすぎだよ…',
            5: '…昔はよかった。（遠い目）',
          },
          debateReplies: {
            2: ['あんたは偉いねえ', 'そうかもしれないねえ'],
            3: ['昔を思い出すよ', '若い考えも大事だね'],
          },
        ),
      ),
      // 若者ケン — 学生、理想主義、改革の会支持
      OppositionCitizen(
        id: 'npc_ken',
        name: '若者ケン',
        job: Job.student,
        personality: '理想主義、短気',
        supportedCandidateId: 'candidate_4',
        stubbornness: 0.4,
        debateTopics: [Concern.education, Concern.employment, Concern.environment],
        dialogs: DialogTree(
          npcName: '若者ケン',
          greeting: 'よっ！選挙行く？俺は絶対行くぜ！',
          moodDialogs: {
            1: 'みんな無関心すぎだよ。俺たちの未来がかかってるのに！',
            2: '改革の会、結構いいと思うんだよね。若者の意見を聞いてくれる。',
            3: '俺は改革の会！古い体質をぶっ壊して新しい町にしようぜ！',
            4: '守りの会とかマジでありえない。老人の町にしたいのかよ！',
            5: '…もう何を言っても無駄なのかな。（うつむく）',
          },
          debateReplies: {
            2: ['それいいね！', 'ちょっと違うかも…'],
            3: ['超わかる！', 'でもそれって現実的？'],
            4: ['は？マジでありえないんだけど！', 'お前も守りの会の回し者か！'],
          },
        ),
      ),
    ];
  }

  @override
  List<Object?> get props => [
        id,
        name,
        job,
        personality,
        supportedCandidateId,
        stubbornness,
        debateTopics,
        dialogs,
      ];
}
