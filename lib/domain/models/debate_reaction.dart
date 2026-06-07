/// 討論会でのプレイヤーの反応を表す列挙型
enum DebateReaction {
  /// 同意
  agree('同意する', '候補者の意見に賛成'),

  /// 反対
  disagree('反対する', '候補者の意見に反対'),

  /// 質問
  question('質問する', 'もっと詳しく聞きたい'),

  /// 沈黙
  silent('沈黙する', '特に反応しない');

  final String label;
  final String description;

  const DebateReaction(this.label, this.description);

  /// 文字列から DebateReaction を復元
  factory DebateReaction.fromString(String value) {
    return DebateReaction.values.firstWhere(
      (r) => r.name == value,
      orElse: () => DebateReaction.silent,
    );
  }
}

/// 討論会の各発言に対するプレイヤーの反応を記録するモデル
class DebateReactionRecord {
  /// 発言者の名前
  final String speakerName;

  /// プレイヤーの反応
  final DebateReaction reaction;

  /// 発言のインデックス（討論会内の何番目の発言か）
  final int speechIndex;

  const DebateReactionRecord({
    required this.speakerName,
    required this.reaction,
    required this.speechIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'speakerName': speakerName,
      'reaction': reaction.name,
      'speechIndex': speechIndex,
    };
  }

  factory DebateReactionRecord.fromJson(Map<String, dynamic> json) {
    return DebateReactionRecord(
      speakerName: json['speakerName'] as String,
      reaction: DebateReaction.fromString(json['reaction'] as String),
      speechIndex: json['speechIndex'] as int,
    );
  }
}
