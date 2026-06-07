import 'dart:math';
import '../models/daily_event.dart';
import '../models/citizen.dart';
import '../models/citizen_enums.dart';
import '../models/society_state.dart';

/// デイリーイベント生成サービス
///
/// 市民の職業や社会状態、選択したアクションに応じたイベントを生成する。
class DailyEventService {
  static final _random = Random();

  /// アクションに応じたランダムイベントを生成する
  /// 約60%の確率でイベント発生。イベントがなければnull（何もない日）。
  static DailyEvent? generateForAction(
    DailyAction action,
    Citizen citizen,
    SocietyState society,
  ) {
    // 60%の確率でイベント発生
    if (_random.nextDouble() > 0.6) return null;

    return _pickEventForAction(action, citizen, society);
  }

  /// 互換性のため残す（従来の generate）
  /// ランダムなアクションを選んで generateForAction を呼ぶ
  static DailyEvent? generate(Citizen citizen, SocietyState society) {
    if (_random.nextDouble() > 0.5) return null;

    final action = DailyAction.values[_random.nextInt(DailyAction.values.length)];
    return _pickEventForAction(action, citizen, society);
  }

  static DailyEvent _pickEventForAction(
    DailyAction action,
    Citizen citizen,
    SocietyState society,
  ) {
    final pool = _buildActionEventPool(action, citizen, society);
    return pool[_random.nextInt(pool.length)];
  }

  static List<DailyEvent> _buildActionEventPool(
    DailyAction action,
    Citizen citizen,
    SocietyState society,
  ) {
    switch (action) {
      case DailyAction.talkToNpc:
        return _buildTalkToNpcPool(citizen, society);
      case DailyAction.gatherInfo:
        return _buildGatherInfoPool(citizen, society);
      case DailyAction.rest:
        return _buildRestPool(citizen, society);
    }
  }

  /// NPCと話す — 社会の空気・噂話・対立市民の意見
  static List<DailyEvent> _buildTalkToNpcPool(
    Citizen citizen,
    SocietyState society,
  ) {
    final pool = <DailyEvent>[
      // 日常会話系
      const DailyEvent(
        title: 'ご近所づきあい',
        description: '隣の家から漬物をおすそ分けしてもらった。最近の町の様子も聞けた。',
        icon: '🏠',
        actionType: DailyAction.talkToNpc,
      ),
      const DailyEvent(
        title: '井戸端会議',
        description: '井戸端で近所の人たちと話した。町の噂話で盛り上がる。',
        icon: '💬',
        actionType: DailyAction.talkToNpc,
      ),
      // 社会ムード別
      if (society.mood < 0.3) ...[
        const DailyEvent(
          title: '商店街のおばちゃん',
          description: '「最近はみんな仲良くてええねえ。選挙の話も穏やかやし」',
          icon: '👵',
          actionType: DailyAction.talkToNpc,
        ),
        const DailyEvent(
          title: '町内会の集い',
          description: 'バーベキュー大会の計画で盛り上がっている。誰が来ても歓迎ムード。',
          icon: '🍖',
          actionType: DailyAction.talkToNpc,
        ),
      ],
      if (society.mood >= 0.3 && society.mood < 0.7) ...[
        const DailyEvent(
          title: 'カフェでの議論',
          description: '隣のテーブルで政策の話が白熱している。「Aさんは福祉が手厚いけど、財源は？」',
          icon: '☕',
          actionType: DailyAction.talkToNpc,
        ),
        const DailyEvent(
          title: '職場の同僚',
          description: '「今回の選挙、どっちに入れる？俺はまだ迷ってるんだよな」',
          icon: '👔',
          actionType: DailyAction.talkToNpc,
        ),
      ],
      if (society.mood >= 0.7) ...[
        const DailyEvent(
          title: '緊張した会話',
          description: '「この町も変わっちまったな...あんまり大きな声じゃ言えないけど」',
          icon: '😰',
          actionType: DailyAction.talkToNpc,
        ),
      ],
      // 選択肢付き — NPCとの会話で意見を聞くか聞かないか
      DailyEvent(
        title: '選挙の話をする？',
        description: '顔見知りの町民が「ところで、次の選挙どう思う？」と話しかけてきた。',
        icon: '🗣️',
        actionType: DailyAction.talkToNpc,
        choices: [
          const EventChoice(
            label: 'しっかり話を聞く',
            resultDescription: '町民の本音が聞けた。社会の空気が少しわかった気がする。',
            effects: {'happiness': 2},
          ),
          const EventChoice(
            label: '軽く流す',
            resultDescription: '「まあ、まだ考え中でね」と当たり障りなく答えた。',
          ),
        ],
      ),
    ];
    return pool;
  }

  /// 情報収集 — 新聞・候補者の公約・政治団体の動向
  static List<DailyEvent> _buildGatherInfoPool(
    Citizen citizen,
    SocietyState society,
  ) {
    final pool = <DailyEvent>[
      // 新聞系
      const DailyEvent(
        title: '朝刊チェック',
        description: '今朝の新聞に町の課題についての特集記事が載っていた。',
        icon: '📰',
        actionType: DailyAction.gatherInfo,
      ),
      const DailyEvent(
        title: '市役所だより',
        description: '広報誌に今期の予算概要が掲載されていた。医療費が少し増えるらしい。',
        icon: '📋',
        actionType: DailyAction.gatherInfo,
      ),
      // 職業別
      if (citizen.job == Job.farmer) ...[
        const DailyEvent(
          title: '農業委員会',
          description: '農業政策についての新しい資料を読んだ。補助金の行方が気になる。',
          icon: '🌾',
          actionType: DailyAction.gatherInfo,
        ),
      ],
      if (citizen.job == Job.merchant) ...[
        const DailyEvent(
          title: '商工会の資料',
          description: '経済動向レポートに目を通した。消費税の議論が活発化している。',
          icon: '📊',
          actionType: DailyAction.gatherInfo,
        ),
      ],
      if (citizen.job == Job.teacher) ...[
        const DailyEvent(
          title: '教育白書',
          description: '教育政策について調べた。予算配分で議論があるようだ。',
          icon: '📚',
          actionType: DailyAction.gatherInfo,
        ),
      ],
      // 選択肢付き — どの情報を深掘りするか
      DailyEvent(
        title: '情報の取捨選択',
        description: 'いくつかの情報源がある。どれを重点的に調べようか？',
        icon: '🔍',
        actionType: DailyAction.gatherInfo,
        choices: [
          const EventChoice(
            label: '候補者の公約を調べる',
            resultDescription: '各候補の公約を詳しく比較できた。投票の判断材料が増えた。',
            effects: {'happiness': 1},
          ),
          const EventChoice(
            label: '政治団体の動向を調べる',
            resultDescription: '各団体の支持基盤と歴史がわかった。政治の構図が見えてきた。',
            effects: {'happiness': 1},
          ),
          const EventChoice(
            label: '統計データを調べる',
            resultDescription: '町の経済指標や人口動態を把握した。客観的な判断ができそうだ。',
            effects: {'employment': 1},
          ),
        ],
      ),
      // 社会ムード別
      if (society.mood >= 0.5) ...[
        const DailyEvent(
          title: '世論調査の結果',
          description: '新聞に世論調査が載っていた。支持率が拮抗しているようだ。',
          icon: '📈',
          actionType: DailyAction.gatherInfo,
        ),
      ],
      if (society.mood >= 0.7) ...[
        const DailyEvent(
          title: '掲示板の張り紙',
          description: '町の掲示板に匿名の政治メッセージが貼られていた。情報の真偽を見極めないと。',
          icon: '📌',
          actionType: DailyAction.gatherInfo,
        ),
      ],
    ];
    return pool;
  }

  /// 休む — 生活パラメータの回復・リラックスイベント
  static List<DailyEvent> _buildRestPool(
    Citizen citizen,
    SocietyState society,
  ) {
    final pool = <DailyEvent>[
      // リラックス系
      const DailyEvent(
        title: 'ゆっくり散歩',
        description: '近所の公園をのんびり散歩した。気持ちがいい。',
        icon: '🚶',
        actionType: DailyAction.rest,
        effects: {'healthcare': 2},
      ),
      const DailyEvent(
        title: '読書の時間',
        description: 'ずっと読みたかった本をゆっくり読んだ。心が落ち着く。',
        icon: '📖',
        actionType: DailyAction.rest,
      ),
      const DailyEvent(
        title: '趣味に没頭',
        description: '今日は好きなことに時間を使えた。いい気分転換になった。',
        icon: '🎨',
        actionType: DailyAction.rest,
      ),
      const DailyEvent(
        title: '早めの就寝',
        description: '今日は早めに布団に入った。明日は元気に過ごせそうだ。',
        icon: '😴',
        actionType: DailyAction.rest,
        effects: {'healthcare': 3},
      ),
      // 職業別
      if (citizen.job == Job.farmer) ...[
        const DailyEvent(
          title: '縁側で一服',
          description: '畑仕事の後、縁側でお茶を飲みながら夕日を眺めた。豊かな時間だ。',
          icon: '🍵',
          actionType: DailyAction.rest,
          effects: {'environment': 1},
        ),
      ],
      if (citizen.job == Job.fisher) ...[
        const DailyEvent(
          title: '海辺で休息',
          description: '漁の合間に浜辺で休憩。潮風が心地よい。',
          icon: '🌊',
          actionType: DailyAction.rest,
          effects: {'environment': 1},
        ),
      ],
      // 選択肢付き
      DailyEvent(
        title: 'どう過ごす？',
        description: '今日は時間ができた。どうやってリフレッシュしよう？',
        icon: '🕰️',
        actionType: DailyAction.rest,
        choices: [
          const EventChoice(
            label: '近所の温泉に行く',
            resultDescription: '温泉で心身ともにリフレッシュ。体の調子が良くなった。',
            effects: {'healthcare': 5, 'lifeCost': -3},
          ),
          const EventChoice(
            label: '家でのんびりする',
            resultDescription: '家でゆっくり過ごした。費用もかからずリラックスできた。',
            effects: {'healthcare': 2},
          ),
          const EventChoice(
            label: '友人と食事に行く',
            resultDescription: '友人と楽しい時間を過ごした。人との繋がりは大事だ。',
            effects: {'happiness': 3, 'lifeCost': -5},
          ),
        ],
      ),
      // 効果付き
      DailyEvent(
        title: 'ジョギング',
        description: '朝のジョギングでいい汗をかいた。健康に良さそうだ。',
        icon: '🏃',
        actionType: DailyAction.rest,
        effects: {'healthcare': 3},
      ),
      DailyEvent(
        title: '家庭菜園',
        description: '庭の小さな畑を手入れした。無農薬の野菜が育っている。',
        icon: '🥬',
        actionType: DailyAction.rest,
        effects: {'lifeCost': -2, 'environment': 1},
      ),
    ];
    return pool;
  }
}
