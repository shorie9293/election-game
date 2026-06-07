/// チュートリアルの各ステップを表す列挙型
enum TutorialStep {
  /// キャラメイク案内
  citizenCreate,
  /// ホーム画面案内
  home,
  /// 街の広場案内
  townSquare,
  /// 討論会案内
  debate,
  /// 投票案内
  vote,
  /// 選挙後案内
  postElection,
}

/// TutorialStep の拡張 - 日本語ラベル
extension TutorialStepLabel on TutorialStep {
  String get label {
    switch (this) {
      case TutorialStep.citizenCreate:
        return 'キャラクター作成';
      case TutorialStep.home:
        return 'ホーム画面';
      case TutorialStep.townSquare:
        return '街の広場';
      case TutorialStep.debate:
        return '討論会';
      case TutorialStep.vote:
        return '投票';
      case TutorialStep.postElection:
        return '選挙後';
    }
  }
}

/// TutorialStep の拡張 - 吹き出し本文（200字以内）
extension TutorialStepDescription on TutorialStep {
  String get description {
    switch (this) {
      case TutorialStep.citizenCreate:
        return 'まずは、あなたの職業を選びましょう。職業によって、政策への関心やNPCの反応が変わります。';
      case TutorialStep.home:
        return 'ここがホーム画面です。生活パラメータを確認し、次の選挙に備えましょう。';
      case TutorialStep.townSquare:
        return '街の広場では、NPCたちと交流できます。彼らの会話から町の空気を感じ取りましょう。';
      case TutorialStep.debate:
        return '討論会です。候補者の主張を聞き、自分の考えを深めましょう。';
      case TutorialStep.vote:
        return 'いよいよ投票です。あなたの一票が、天照町の未来を決めます。';
      case TutorialStep.postElection:
        return '選挙が終わりました。当選者の政策が町にどう影響するか、見守りましょう。';
    }
  }
}
