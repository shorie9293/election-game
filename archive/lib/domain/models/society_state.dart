import 'package:equatable/equatable.dart';

class SocietyState extends Equatable {
  final double happiness;
  final double mood;
  final String? currentLeaderId;
  final int electionCount;

  const SocietyState({
    required this.happiness,
    required this.mood,
    this.currentLeaderId,
    required this.electionCount,
  });

  factory SocietyState.initial() {
    return const SocietyState(
      happiness: 50.0,
      mood: 0.3,
      electionCount: 0,
    );
  }

  String get moodLabel {
    if (mood < 0.2) return 'なれ合い';
    if (mood < 0.4) return '融和';
    if (mood < 0.6) return '健全な対立';
    if (mood < 0.8) return '不健全な対立';
    return '独裁';
  }

  SocietyState copyWith({
    double? happiness,
    double? mood,
    String? currentLeaderId,
    int? electionCount,
    bool clearLeader = false,
  }) {
    return SocietyState(
      happiness: happiness ?? this.happiness,
      mood: mood ?? this.mood,
      currentLeaderId:
          clearLeader ? null : (currentLeaderId ?? this.currentLeaderId),
      electionCount: electionCount ?? this.electionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'happiness': happiness,
      'mood': mood,
      'currentLeaderId': currentLeaderId,
      'electionCount': electionCount,
    };
  }

  factory SocietyState.fromJson(Map<String, dynamic> json) {
    return SocietyState(
      happiness: (json['happiness'] as num).toDouble(),
      mood: (json['mood'] as num).toDouble(),
      currentLeaderId: json['currentLeaderId'] as String?,
      electionCount: json['electionCount'] as int,
    );
  }

  @override
  List<Object?> get props =>
      [happiness, mood, currentLeaderId, electionCount];
}
