import 'package:equatable/equatable.dart';
import 'candidate.dart';

class Election extends Equatable {
  final String id;
  final String title;
  final String scale;
  final List<Candidate> candidates;
  final Map<String, int>? voteCounts;
  final String? winnerId;

  const Election({
    required this.id,
    required this.title,
    required this.scale,
    required this.candidates,
    this.voteCounts,
    this.winnerId,
  });

  factory Election.sampleVillage() {
    return Election(
      id: 'election_1',
      title: '天照町 町長選挙',
      scale: 'village',
      candidates: Candidate.samples(),
    );
  }

  Election copyWith({
    String? id,
    String? title,
    String? scale,
    List<Candidate>? candidates,
    Map<String, int>? voteCounts,
    String? winnerId,
  }) {
    return Election(
      id: id ?? this.id,
      title: title ?? this.title,
      scale: scale ?? this.scale,
      candidates: candidates ?? this.candidates,
      voteCounts: voteCounts ?? this.voteCounts,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scale': scale,
      'candidates': candidates.map((c) => c.toJson()).toList(),
      'voteCounts': voteCounts,
      'winnerId': winnerId,
    };
  }

  factory Election.fromJson(Map<String, dynamic> json) {
    return Election(
      id: json['id'] as String,
      title: json['title'] as String,
      scale: json['scale'] as String,
      candidates: (json['candidates'] as List)
          .map((c) => Candidate.fromJson(c as Map<String, dynamic>))
          .toList(),
      voteCounts: json['voteCounts'] != null
          ? Map<String, int>.from(json['voteCounts'] as Map)
          : null,
      winnerId: json['winnerId'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, scale, candidates, voteCounts, winnerId];
}
