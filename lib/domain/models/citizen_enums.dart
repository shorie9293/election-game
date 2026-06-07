/// 職業を表す列挙型
enum Job {
  farmer('農家'),
  fisher('漁師'),
  carpenter('大工'),
  merchant('商人'),
  teacher('教師'),
  doctor('医者'),
  official('役人'),
  artisan('職人'),
  student('学生'),
  unemployed('無職');

  final String label;
  const Job(this.label);
}

/// 関心事を表す列挙型
enum Concern {
  agriculture('農業政策'),
  economy('経済政策'),
  education('教育政策'),
  employment('雇用政策'),
  environment('環境政策'),
  healthcare('医療政策'),
  safety('治安政策'),
  tax('税制');

  final String label;
  const Concern(this.label);
}

/// 生活パラメータのキー定数
class LifeParamKeys {
  LifeParamKeys._();

  static const all = [
    'lifeCost',
    'healthcare',
    'education',
    'employment',
    'environment',
    'safety',
  ];

  /// キーに対応する日本語ラベルを返す
  static String label(String key) {
    const labels = <String, String>{
      'lifeCost': '💰 生活費',
      'healthcare': '🏥 医療',
      'education': '🏫 教育',
      'employment': '🏭 仕事',
      'environment': '🌳 環境',
      'safety': '🚔 治安',
    };
    return labels[key] ?? '';
  }
}
