import 'package:equatable/equatable.dart';

/// 公約（政策）を表すモデル
class Policy extends Equatable {
  final String title;
  final String description;
  final String category;
  final Map<String, int> effects; // lifeParamKey -> 変化量

  const Policy({
    required this.title,
    required this.description,
    required this.category,
    required this.effects,
  });

  Policy copyWith({
    String? title,
    String? description,
    String? category,
    Map<String, int>? effects,
  }) {
    return Policy(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      effects: effects ?? this.effects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'effects': effects,
    };
  }

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      effects: Map<String, int>.from(json['effects'] as Map),
    );
  }

  @override
  List<Object?> get props => [title, description, category, effects];
}

/// 候補者を表すモデル
class Candidate extends Equatable {
  final String id;
  final String name;
  final String portraitKey;
  final String faction;
  final String personality;
  final List<Policy> policies;

  const Candidate({
    required this.id,
    required this.name,
    required this.portraitKey,
    required this.faction,
    required this.personality,
    required this.policies,
  });

  /// 全公約の効果を合計
  Map<String, int> get totalEffects {
    final effects = <String, int>{};
    for (final policy in policies) {
      for (final entry in policy.effects.entries) {
        effects[entry.key] = (effects[entry.key] ?? 0) + entry.value;
      }
    }
    return effects;
  }

  static List<Candidate> samples() {
    return [
      Candidate(
        id: 'candidate_1',
        name: '山田太郎',
        portraitKey: 'portrait_yamada',
        faction: '発展の会',
        personality: '経済成長で皆が豊かに',
        policies: [
          Policy(
            title: '大規模開発',
            description: '公共事業で経済を活性化',
            category: '経済',
            effects: {'employment': 10, 'environment': -5, 'lifeCost': 3},
          ),
          Policy(
            title: '減税',
            description: '所得税を引き下げる',
            category: '経済',
            effects: {'lifeCost': -10, 'healthcare': -5},
          ),
        ],
      ),
      Candidate(
        id: 'candidate_2',
        name: '佐藤花子',
        portraitKey: 'portrait_sato',
        faction: '共生の会',
        personality: '支え合う社会を',
        policies: [
          Policy(
            title: '医療拡充',
            description: '医療アクセスを改善',
            category: '医療',
            effects: {'healthcare': 10, 'lifeCost': 5},
          ),
          Policy(
            title: '教育無償化',
            description: '教育費を無料に',
            category: '教育',
            effects: {'education': 10, 'lifeCost': 5},
          ),
        ],
      ),
      Candidate(
        id: 'candidate_3',
        name: '鈴木一郎',
        portraitKey: 'portrait_suzuki',
        faction: '守りの会',
        personality: '伝統と安定を守る',
        policies: [
          Policy(
            title: '治安強化',
            description: '防犯カメラを設置',
            category: '治安',
            effects: {'safety': 10, 'lifeCost': 3},
          ),
          Policy(
            title: '地場産業保護',
            description: '地元産業を支援',
            category: '経済',
            effects: {'employment': 5, 'environment': 3, 'lifeCost': 3},
          ),
        ],
      ),
      Candidate(
        id: 'candidate_4',
        name: '田中美咲',
        portraitKey: 'portrait_tanaka',
        faction: '改革の会',
        personality: '若者の声を政治に',
        policies: [
          Policy(
            title: '起業支援',
            description: 'スタートアップ補助金',
            category: '経済',
            effects: {'employment': 8, 'lifeCost': -3},
          ),
          Policy(
            title: '環境投資',
            description: '再生可能エネルギー',
            category: '環境',
            effects: {'environment': 8, 'lifeCost': 3},
          ),
        ],
      ),
    ];
  }

  Candidate copyWith({
    String? id,
    String? name,
    String? portraitKey,
    String? faction,
    String? personality,
    List<Policy>? policies,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      portraitKey: portraitKey ?? this.portraitKey,
      faction: faction ?? this.faction,
      personality: personality ?? this.personality,
      policies: policies ?? this.policies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'portraitKey': portraitKey,
      'faction': faction,
      'personality': personality,
      'policies': policies.map((p) => p.toJson()).toList(),
    };
  }

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] as String,
      name: json['name'] as String,
      portraitKey: json['portraitKey'] as String,
      faction: json['faction'] as String,
      personality: json['personality'] as String,
      policies: (json['policies'] as List)
          .map((p) => Policy.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, portraitKey, faction, personality, policies];
}
