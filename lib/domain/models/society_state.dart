import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:election_game/core/theme/retro_theme.dart';

/// 社会状態を表すモデル
class SocietyState extends Equatable {
  final double happiness; // 0〜100
  final double mood; // 0.0(なれ合い)〜1.0(独裁)
  final String? currentLeaderId;
  final int electionCount;

  const SocietyState({
    required this.happiness,
    required this.mood,
    required this.electionCount,
    this.currentLeaderId,
  });

  factory SocietyState.initial() {
    return const SocietyState(
      happiness: 50.0,
      mood: 0.3,
      electionCount: 0,
    );
  }

  /// ムードの日本語ラベル
  String get moodLabel {
    if (mood < 0.2) return 'なれ合い';
    if (mood < 0.4) return '融和';
    if (mood < 0.6) return '健全な対立';
    if (mood < 0.8) return '不健全な対立';
    return '独裁';
  }

  /// ムードに対応する色
  Color get moodColor {
    if (mood < 0.2) return RetroPalette.moodCollusion;
    if (mood < 0.4) return RetroPalette.moodHarmony;
    if (mood < 0.6) return RetroPalette.moodHealthyDebate;
    if (mood < 0.8) return RetroPalette.moodUnhealthy;
    return RetroPalette.moodDictatorship;
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
