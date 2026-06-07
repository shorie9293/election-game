import 'package:equatable/equatable.dart';
import 'citizen_enums.dart';

/// 関心事の獲得履歴を表すモデル
///
/// プレイヤーの政治的関心がいつ・どのような理由で変化したかを追跡する。
class ConcernEvolution extends Equatable {
  /// 獲得した関心事
  final Concern concern;

  /// 獲得時の選挙回数（1ベース。キャラメイク時の初期関心事は 0）
  final int acquiredAtElection;

  /// 獲得理由（表示用）
  final String reason;

  const ConcernEvolution({
    required this.concern,
    required this.acquiredAtElection,
    required this.reason,
  });

  /// 初期関心事（キャラメイク時）を表す
  factory ConcernEvolution.initial(Concern concern) {
    return ConcernEvolution(
      concern: concern,
      acquiredAtElection: 0,
      reason: '職業に基づく初期の関心事',
    );
  }

  /// 経験を通じて獲得した関心事か
  bool get isAcquired => acquiredAtElection > 0;

  Map<String, dynamic> toJson() {
    return {
      'concern': concern.name,
      'acquiredAtElection': acquiredAtElection,
      'reason': reason,
    };
  }

  factory ConcernEvolution.fromJson(Map<String, dynamic> json) {
    return ConcernEvolution(
      concern: Concern.values.firstWhere((c) => c.name == json['concern']),
      acquiredAtElection: json['acquiredAtElection'] as int,
      reason: json['reason'] as String,
    );
  }

  @override
  List<Object?> get props => [concern, acquiredAtElection, reason];
}
