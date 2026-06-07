/// プレイヤーが選択できる日々の行動
enum DailyAction {
  /// NPCと話す（社会の空気を感じる、対立市民の意見を聞く）
  talkToNpc,

  /// 情報収集（新聞を読む、候補者の公約を調べる）
  gatherInfo,

  /// 休む（生活パラメータが少し回復）
  rest,
}

/// 選択肢付きイベントの1選択肢
class EventChoice {
  final String label;
  final String resultDescription;
  final Map<String, int>? effects; // lifeParamKey -> 変化量

  const EventChoice({
    required this.label,
    required this.resultDescription,
    this.effects,
  });
}

/// デイリーイベントモデル
///
/// 「1日を過ごす」時にランダム発生する町の出来事。
/// 生活パラメータに小さな影響を与える場合もある。
/// choicesが非nullの場合、プレイヤーに選択肢を提示する。
class DailyEvent {
  final String title;
  final String description;
  final String icon;
  final Map<String, int>? effects; // lifeParamKey -> 変化量（null=効果なし）
  final List<EventChoice>? choices; // 選択肢（null=自動進行、非null=選択肢表示）
  final DailyAction? actionType; // どのアクションから発生したか

  const DailyEvent({
    required this.title,
    required this.description,
    required this.icon,
    this.effects,
    this.choices,
    this.actionType,
  });
}
