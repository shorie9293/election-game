/// 選挙スケール（段階進行）を表す列挙型
///
/// 神話文体：天照村→天照町→天照市
/// 三つの段階を経て、選挙の規模と複雑さが増大する。
enum ElectionScale {
  /// 村（Village）：初期段階、小規模な村長選挙
  /// NPC数5、政治は単純
  village(
    displayName: '天照村',
    title: '村長選挙',
    electionsNeeded: 3,
    npcCount: 5,
    politicalComplexity: 'simple',
  ),

  /// 町（Town）：中期段階、中規模な町長選挙
  /// NPC数8、政治は中程度
  town(
    displayName: '天照町',
    title: '町長選挙',
    electionsNeeded: 3,
    npcCount: 8,
    politicalComplexity: 'moderate',
  ),

  /// 市（City）：最終段階、大規模な市長選挙
  /// NPC数12、政治は複雑
  city(
    displayName: '天照市',
    title: '市長選挙',
    electionsNeeded: 3,
    npcCount: 12,
    politicalComplexity: 'complex',
  );

  /// 表示名（天照村・天照町・天照市）
  final String displayName;

  /// 選挙タイトル（村長選挙・町長選挙・市長選挙）
  final String title;

  /// この段階で必要な選挙回数（各段階3回）
  final int electionsNeeded;

  /// NPC数（村5・町8・市12）
  final int npcCount;

  /// 政治的複雑度（simple/moderate/complex）
  final String politicalComplexity;

  const ElectionScale({
    required this.displayName,
    required this.title,
    required this.electionsNeeded,
    required this.npcCount,
    required this.politicalComplexity,
  });

  /// 次の段階へ進む
  /// 村→町→市→null
  ElectionScale? get advanceTo {
    switch (this) {
      case ElectionScale.village:
        return ElectionScale.town;
      case ElectionScale.town:
        return ElectionScale.city;
      case ElectionScale.city:
        return null;
    }
  }

  /// 初期段階（村）
  static ElectionScale initial() => ElectionScale.village;

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'title': title,
      'electionsNeeded': electionsNeeded,
      'npcCount': npcCount,
      'politicalComplexity': politicalComplexity,
    };
  }

  factory ElectionScale.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as String;
    return ElectionScale.values.firstWhere(
      (scale) => scale.displayName == displayName,
      orElse: () => ElectionScale.village,
    );
  }
}
