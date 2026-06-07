/// ゲームの進行フェーズを表すenum
enum GamePhase {
  /// キャラクター作成
  citizenCreate,

  /// ホーム（生活パラメータ表示・選挙待機）
  home,

  /// 選挙告示（候補者発表）
  electionAnnouncement,

  /// 討論会（候補者討論）
  debate,

  /// 投票
  vote,

  /// 選挙結果表示
  result,

  /// エンディング
  ending,
}
