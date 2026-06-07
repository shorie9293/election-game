import 'package:equatable/equatable.dart';
import 'citizen_enums.dart';

/// 市民（プレイヤー）を表すモデル
class Citizen extends Equatable {
  final String name;
  final Job job;
  final List<Concern> concerns;
  final Map<String, int> lifeParams;

  const Citizen({
    required this.name,
    required this.job,
    required this.concerns,
    required this.lifeParams,
  });

  /// 職業に応じた初期値で市民を生成
  factory Citizen.initial(Job job) {
    final baseLifeParams = <String, int>{
      'lifeCost': 50,
      'healthcare': 50,
      'education': 50,
      'employment': 50,
      'environment': 50,
      'safety': 50,
    };

    List<Concern> concerns;
    switch (job) {
      case Job.farmer:
        baseLifeParams['environment'] = 70;
        baseLifeParams['lifeCost'] = 40;
        concerns = [Concern.agriculture, Concern.environment];
      case Job.fisher:
        baseLifeParams['lifeCost'] = 40;
        baseLifeParams['environment'] = 55;
        concerns = [Concern.environment, Concern.employment];
      case Job.carpenter:
        baseLifeParams['lifeCost'] = 45;
        baseLifeParams['employment'] = 50;
        concerns = [Concern.economy, Concern.employment];
      case Job.merchant:
        baseLifeParams['employment'] = 60;
        baseLifeParams['lifeCost'] = 50;
        concerns = [Concern.economy, Concern.tax];
      case Job.teacher:
        baseLifeParams['education'] = 70;
        baseLifeParams['healthcare'] = 50;
        concerns = [Concern.education, Concern.healthcare];
      case Job.doctor:
        baseLifeParams['healthcare'] = 75;
        baseLifeParams['lifeCost'] = 55;
        concerns = [Concern.healthcare, Concern.healthcare];
      case Job.official:
        baseLifeParams['safety'] = 60;
        baseLifeParams['education'] = 55;
        concerns = [Concern.safety, Concern.education];
      case Job.artisan:
        baseLifeParams['employment'] = 55;
        baseLifeParams['environment'] = 50;
        concerns = [Concern.economy, Concern.employment];
      case Job.student:
        baseLifeParams['education'] = 50;
        baseLifeParams['employment'] = 40;
        concerns = [Concern.education, Concern.employment];
      case Job.unemployed:
        baseLifeParams['lifeCost'] = 30;
        baseLifeParams['employment'] = 20;
        concerns = [Concern.employment, Concern.healthcare];
    }

    return Citizen(
      name: '',
      job: job,
      concerns: concerns,
      lifeParams: baseLifeParams,
    );
  }

  /// 政策効果をライフパラメータに適用
  Citizen applyPolicyEffects(Map<String, int> effects) {
    final newLifeParams = Map<String, int>.from(lifeParams);
    for (final entry in effects.entries) {
      final currentValue = newLifeParams[entry.key] ?? 0;
      newLifeParams[entry.key] = (currentValue + entry.value).clamp(0, 100);
    }
    return copyWith(lifeParams: newLifeParams);
  }

  Citizen copyWith({
    String? name,
    Job? job,
    List<Concern>? concerns,
    Map<String, int>? lifeParams,
  }) {
    return Citizen(
      name: name ?? this.name,
      job: job ?? this.job,
      concerns: concerns ?? this.concerns,
      lifeParams: lifeParams ?? this.lifeParams,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'job': job.name,
      'concerns': concerns.map((c) => c.name).toList(),
      'lifeParams': lifeParams,
    };
  }

  factory Citizen.fromJson(Map<String, dynamic> json) {
    return Citizen(
      name: json['name'] as String,
      job: Job.values.firstWhere((j) => j.name == json['job']),
      concerns: (json['concerns'] as List)
          .map((c) => Concern.values.firstWhere((x) => x.name == c))
          .toList(),
      lifeParams: Map<String, int>.from(json['lifeParams'] as Map),
    );
  }

  @override
  List<Object?> get props => [name, job, concerns, lifeParams];
}
