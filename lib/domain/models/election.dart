import 'package:equatable/equatable.dart';
import 'candidate.dart';
import 'election_scale.dart';

/// 選挙を表すモデル
class Election extends Equatable {
  final String id;
  final String title;
  final ElectionScale scale;
  final List<Candidate> candidates;
  final int turnDeadline;
  final Map<String, int>? voteCounts;
  final String? winnerId;
  final String? voterId; // 投票者（プレイヤー市民）のID

  const Election({
    required this.id,
    required this.title,
    required this.scale,
    required this.candidates,
    this.turnDeadline = 3,
    this.voteCounts,
    this.winnerId,
    this.voterId,
  });

  /// 選挙が完了したか
  bool get completed => winnerId != null && voteCounts != null;

  /// サンプル選挙を生成
  factory Election.sample() {
    return Election(
      id: 'election_1',
      title: '天照町 町長選挙',
      scale: ElectionScale.town,
      candidates: Candidate.samples(),
      turnDeadline: 3,
    );
  }

  Election copyWith({
    String? id,
    String? title,
    ElectionScale? scale,
    List<Candidate>? candidates,
    int? turnDeadline,
    Map<String, int>? voteCounts,
    String? winnerId,
    String? voterId,
    bool clearWinner = false,
    bool clearVoterId = false,
  }) {
    return Election(
      id: id ?? this.id,
      title: title ?? this.title,
      scale: scale ?? this.scale,
      candidates: candidates ?? this.candidates,
      turnDeadline: turnDeadline ?? this.turnDeadline,
      voteCounts: voteCounts ?? this.voteCounts,
      winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
      voterId: clearVoterId ? null : (voterId ?? this.voterId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scale': scale.toJson(),
      'candidates': candidates.map((c) => c.toJson()).toList(),
      'turnDeadline': turnDeadline,
      'voteCounts': voteCounts,
      'winnerId': winnerId,
      'voterId': voterId,
    };
  }

  factory Election.fromJson(Map<String, dynamic> json) {
    return Election(
      id: json['id'] as String,
      title: json['title'] as String,
      scale: json['scale'] != null
          ? ElectionScale.fromJson(json['scale'] as Map<String, dynamic>)
          : ElectionScale.town,
      candidates: (json['candidates'] as List)
          .map((c) => Candidate.fromJson(c as Map<String, dynamic>))
          .toList(),
      turnDeadline: json['turnDeadline'] as int? ?? 3,
      voteCounts: json['voteCounts'] != null
          ? Map<String, int>.from(json['voteCounts'] as Map)
          : null,
      winnerId: json['winnerId'] as String?,
      voterId: json['voterId'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, scale, candidates, turnDeadline, voteCounts, winnerId, voterId];
}
