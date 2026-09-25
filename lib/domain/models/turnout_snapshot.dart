import 'package:equatable/equatable.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election_scale.dart';

/// 職業ごとの投票率スナップショット
class JobTurnout extends Equatable {
  /// 職業
  final Job job;

  /// 有権者数
  final int eligible;

  /// 投票者数
  final int voted;

  /// 不変条件は本体で検証（const 不可・ArgumentError を throw）
  JobTurnout({
    required this.job,
    required this.eligible,
    required this.voted,
  }) {
    if (eligible < 0) {
      throw ArgumentError.value(eligible, 'eligible', '負値は禁止');
    }
    if (voted < 0) {
      throw ArgumentError.value(voted, 'voted', '負値は禁止');
    }
    if (voted > eligible) {
      throw ArgumentError.value(
          voted, 'voted', 'voted は eligible を超えられない');
    }
  }

  /// 投票率（0.0-1.0）。有権者0人のときは 0.0
  double get rate => eligible == 0 ? 0.0 : voted / eligible;

  /// 投票率ラベル（例: 0.425 → '42.5%'）
  String get rateLabel => '${(rate * 100).toStringAsFixed(1)}%';

  /// 棄権者数
  int get abstained => eligible - voted;

  @override
  List<Object?> get props => [job, eligible, voted];
}

/// 選挙の投票率スナップショット
///
/// 職業別内訳と全体参加率・関心ラベルを保持する。
class TurnoutSnapshot extends Equatable {
  /// 選挙タイトル（空文字禁止）
  final String electionTitle;

  /// 選挙規模
  final ElectionScale scale;

  /// 職業別内訳（空リスト禁止）
  final List<JobTurnout> jobBreakdown;

  /// プレイヤーが棄権したか
  final bool playerAbstained;

  /// 不変条件は本体で検証（ArgumentError を throw）
  TurnoutSnapshot({
    required this.electionTitle,
    required this.scale,
    required this.jobBreakdown,
    this.playerAbstained = false,
  }) {
    if (electionTitle.isEmpty) {
      throw ArgumentError.value(
          electionTitle, 'electionTitle', '空文字は禁止');
    }
    if (jobBreakdown.isEmpty) {
      throw ArgumentError.value(jobBreakdown, 'jobBreakdown', '空リストは禁止');
    }
  }

  /// 有権者数（職業別の eligible 合計）
  int get eligibleVoters =>
      jobBreakdown.fold(0, (sum, j) => sum + j.eligible);

  /// 投票者数（職業別の voted 合計）
  int get votesCast => jobBreakdown.fold(0, (sum, j) => sum + j.voted);

  /// 棄権者数
  int get abstentionCount => eligibleVoters - votesCast;

  /// 全体投票率（0.0-1.0）。有権者0人のときは 0.0
  double get turnoutRate =>
      eligibleVoters == 0 ? 0.0 : votesCast / eligibleVoters;

  /// 全体投票率ラベル（例: '62.4%'）
  String get turnoutPercentLabel =>
      '${(turnoutRate * 100).toStringAsFixed(1)}%';

  /// 関心ラベル: 0.6以上 → '高い関心' / 0.45以上 → 'ふつう' / else → '低い関心'
  String get turnoutLabel {
    if (turnoutRate >= 0.6) return '高い関心';
    if (turnoutRate >= 0.45) return 'ふつう';
    return '低い関心';
  }

  /// 最も投票率の高い職業（同率は Job.index 昇順で先。空なら null）
  JobTurnout? get highestJob {
    if (jobBreakdown.isEmpty) return null;
    JobTurnout? best;
    for (final jt in jobBreakdown) {
      if (best == null ||
          jt.rate > best.rate ||
          (jt.rate == best.rate && jt.job.index < best.job.index)) {
        best = jt;
      }
    }
    return best;
  }

  /// 最も投票率の低い職業（同率は Job.index 昇順で先。空なら null）
  JobTurnout? get lowestJob {
    if (jobBreakdown.isEmpty) return null;
    JobTurnout? best;
    for (final jt in jobBreakdown) {
      if (best == null ||
          jt.rate < best.rate ||
          (jt.rate == best.rate && jt.job.index < best.job.index)) {
        best = jt;
      }
    }
    return best;
  }

  @override
  List<Object?> get props =>
      [electionTitle, scale, jobBreakdown, playerAbstained];
}

/// 棄権の反実仮想（もし棄権者が投票していたら）
class TurnoutCounterfactual extends Equatable {
  /// 実際の当選者ID
  final String? actualWinnerId;

  /// 実際の当選者名
  final String? actualWinnerName;

  /// 反実仮想の当選者ID
  final String? counterfactualWinnerId;

  /// 反実仮想の当選者名
  final String? counterfactualWinnerName;

  /// 実際の投票を votesCast にスケールした票
  final Map<String, int> actualVotes;

  /// 棄権者を加算後の票
  final Map<String, int> counterfactualVotes;

  /// 棄権者数（負値禁止）
  final int abstentionCount;

  /// 不変条件は本体で検証（ArgumentError を throw）
  TurnoutCounterfactual({
    required this.actualWinnerId,
    required this.actualWinnerName,
    required this.counterfactualWinnerId,
    required this.counterfactualWinnerName,
    required this.actualVotes,
    required this.counterfactualVotes,
    required this.abstentionCount,
  }) {
    if (abstentionCount < 0) {
      throw ArgumentError.value(
          abstentionCount, 'abstentionCount', '負値は禁止');
    }
  }

  /// 棄権が当選者を変えたか
  bool get winnerChanged => counterfactualWinnerId != actualWinnerId;

  /// 判定ラベル
  String get verdictLabel => winnerChanged
      ? '棄権が当選者を変えた'
      : '棄権があっても当選者は変わらない';

  @override
  List<Object?> get props => [
        actualWinnerId,
        actualWinnerName,
        counterfactualWinnerId,
        counterfactualWinnerName,
        _sortedEntries(actualVotes),
        _sortedEntries(counterfactualVotes),
        abstentionCount,
      ];

  static List<String> _sortedEntries(Map<String, int> map) {
    final keys = map.keys.toList()..sort();
    return [for (final k in keys) '$k=${map[k]}'];
  }
}
