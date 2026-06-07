import 'package:equatable/equatable.dart';

enum Job {
  farmer,
  fisher,
  carpenter,
  merchant,
  teacher,
  doctor,
  official,
  artisan,
  student,
  unemployed,
}

class Citizen extends Equatable {
  final String name;
  final Job job;
  final List<String> concerns;
  final Map<String, int> lifeParams;

  const Citizen({
    required this.name,
    required this.job,
    required this.concerns,
    required this.lifeParams,
  });

  factory Citizen.initial(Job job) {
    final baseLifeParams = <String, int>{
      'lifeCost': 50,
      'healthcare': 50,
      'education': 50,
      'employment': 50,
      'environment': 50,
      'safety': 50,
    };

    switch (job) {
      case Job.farmer:
        baseLifeParams['environment'] = 70;
        baseLifeParams['lifeCost'] = 40;
        return Citizen(
          name: '',
          job: job,
          concerns: ['農業政策', '気候変動'],
          lifeParams: baseLifeParams,
        );
      case Job.merchant:
        baseLifeParams['employment'] = 60;
        baseLifeParams['lifeCost'] = 50;
        return Citizen(
          name: '',
          job: job,
          concerns: ['経済政策', '税制'],
          lifeParams: baseLifeParams,
        );
      case Job.teacher:
        baseLifeParams['education'] = 70;
        baseLifeParams['healthcare'] = 50;
        return Citizen(
          name: '',
          job: job,
          concerns: ['教育政策', '社会保障'],
          lifeParams: baseLifeParams,
        );
      case Job.student:
        baseLifeParams['education'] = 50;
        baseLifeParams['employment'] = 40;
        return Citizen(
          name: '',
          job: job,
          concerns: ['教育政策', '雇用政策'],
          lifeParams: baseLifeParams,
        );
      case Job.doctor:
        baseLifeParams['healthcare'] = 75;
        baseLifeParams['lifeCost'] = 55;
        return Citizen(
          name: '',
          job: job,
          concerns: ['医療政策', '社会保障'],
          lifeParams: baseLifeParams,
        );
      case Job.unemployed:
        baseLifeParams['lifeCost'] = 30;
        baseLifeParams['employment'] = 20;
        return Citizen(
          name: '',
          job: job,
          concerns: ['雇用政策', '社会保障'],
          lifeParams: baseLifeParams,
        );
      case Job.fisher:
        baseLifeParams['lifeCost'] = 40;
        baseLifeParams['environment'] = 55;
        return Citizen(
          name: '',
          job: job,
          concerns: ['生活', '雇用'],
          lifeParams: baseLifeParams,
        );
      case Job.carpenter:
        baseLifeParams['lifeCost'] = 45;
        baseLifeParams['employment'] = 50;
        return Citizen(
          name: '',
          job: job,
          concerns: ['生活', '経済'],
          lifeParams: baseLifeParams,
        );
      case Job.artisan:
        baseLifeParams['employment'] = 55;
        baseLifeParams['environment'] = 50;
        return Citizen(
          name: '',
          job: job,
          concerns: ['経済', '雇用'],
          lifeParams: baseLifeParams,
        );
      case Job.official:
        baseLifeParams['safety'] = 60;
        baseLifeParams['education'] = 55;
        return Citizen(
          name: '',
          job: job,
          concerns: ['治安', '教育'],
          lifeParams: baseLifeParams,
        );
    }
  }

  Citizen copyWith({
    String? name,
    Job? job,
    List<String>? concerns,
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
      'concerns': concerns,
      'lifeParams': lifeParams,
    };
  }

  factory Citizen.fromJson(Map<String, dynamic> json) {
    return Citizen(
      name: json['name'] as String,
      job: Job.values.firstWhere((j) => j.name == json['job']),
      concerns: List<String>.from(json['concerns'] as List),
      lifeParams: Map<String, int>.from(json['lifeParams'] as Map),
    );
  }

  @override
  List<Object?> get props => [name, job, concerns, lifeParams];
}
