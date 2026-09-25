import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';

/// 投票率（有権者参加率）の可視化画面。
///
/// 全体の投票率・棄権者数・職業別の参加率と、
/// 「もし棄権者が全員投票していたら」の反実仮想を提示する。
/// 計算は上位（TurnoutService）で済ませ、この画面は表示に徹する。
class TurnoutScreen extends StatelessWidget {
  /// 選挙タイトル
  final String electionTitle;

  /// 投票率スナップショット（必須）
  final TurnoutSnapshot turnout;

  /// 棄権の反実仮想（未完了の選挙では null）
  final TurnoutCounterfactual? counterfactual;

  const TurnoutScreen({
    super.key,
    required this.electionTitle,
    required this.turnout,
    this.counterfactual,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.turnoutScreen,
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: Semantics(
          key: AppKeys.turnoutTitle,
          header: true,
          label: '投票率',
          child: const Text('投票率'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 見出しカード（選挙名＋投票率）
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.gold),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      electionTitle,
                      style: const TextStyle(
                        color: RetroPalette.textAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '投票率',
                      style: TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      turnout.turnoutPercentLabel,
                      key: AppKeys.turnoutRateLabel,
                      style: const TextStyle(
                        color: RetroPalette.gold,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      turnout.turnoutLabel,
                      key: AppKeys.turnoutLevelLabel,
                      style: const TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '有権者 ${turnout.eligibleVoters}人 / '
                      '投票 ${turnout.votesCast}人 / '
                      '棄権 ${turnout.abstentionCount}人',
                      key: AppKeys.turnoutVoterSummary,
                      style: const TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 職業別の参加率
              Container(
                key: AppKeys.turnoutJobList,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.panelBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '職業別の参加率',
                      style: TextStyle(
                        color: RetroPalette.textAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final jobTurnout in turnout.jobBreakdown) ...[
                      _JobTurnoutRow(jobTurnout: jobTurnout),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 反実仮想（棄権が結果をどう変えたか）
              if (counterfactual != null)
                _CounterfactualCard(counterfactual: counterfactual!),

              const SizedBox(height: 8),
              const Text(
                '投票率は世論のムード・頑固さと選挙規模から試算した参考値です',
                style: TextStyle(
                  color: RetroPalette.voteAbstain,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 職業1件ぶんの参加率行。
class _JobTurnoutRow extends StatelessWidget {
  final JobTurnout jobTurnout;

  const _JobTurnoutRow({required this.jobTurnout});

  @override
  Widget build(BuildContext context) {
    final rate = jobTurnout.rate;
    final highlightColor = rate >= 0.6
        ? RetroPalette.success
        : (rate >= 0.45 ? RetroPalette.gold : RetroPalette.warning);
    return Column(
      key: AppKeys.turnoutJobRow(jobTurnout.job.name),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                jobTurnout.job.label,
                style: const TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              jobTurnout.rateLabel,
              key: AppKeys.turnoutJobRate(jobTurnout.job.name),
              style: TextStyle(color: highlightColor, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: rate,
          backgroundColor: RetroPalette.panelBorder,
          valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
        ),
        const SizedBox(height: 4),
        Text(
          '${jobTurnout.voted} / ${jobTurnout.eligible}人（棄権 ${jobTurnout.abstained}人）',
          style: const TextStyle(
            color: RetroPalette.voteAbstain,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// 「もし棄権者が全員投票していたら」カード。
class _CounterfactualCard extends StatelessWidget {
  final TurnoutCounterfactual counterfactual;

  const _CounterfactualCard({required this.counterfactual});

  @override
  Widget build(BuildContext context) {
    final changed = counterfactual.winnerChanged;
    return Container(
      key: AppKeys.turnoutCounterfactualCard,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(
          color: changed ? RetroPalette.gold : RetroPalette.panelBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'もし棄権者が全員投票していたら',
            style: TextStyle(
              color: RetroPalette.textAccent,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '実際の当選者: ${counterfactual.actualWinnerName ?? '不明'}',
            style: const TextStyle(
              color: RetroPalette.textNormal,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '全員投票した場合: ${counterfactual.counterfactualWinnerName ?? '不明'}',
            style: TextStyle(
              color: changed ? RetroPalette.gold : RetroPalette.textNormal,
              fontSize: 13,
              fontWeight: changed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            counterfactual.verdictLabel,
            key: AppKeys.turnoutVerdictLabel,
            style: TextStyle(
              color: changed ? RetroPalette.gold : RetroPalette.textNormal,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '棄権した ${counterfactual.abstentionCount}人 ぶんの票を、'
            '支持の厚い候補者へ按分した試算です',
            style: const TextStyle(
              color: RetroPalette.voteAbstain,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
