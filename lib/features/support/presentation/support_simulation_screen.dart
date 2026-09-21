import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/services/support_simulation_service.dart';

/// 支持率シミュレーション画面。
///
/// 現在の候補者と世論から支持率を試算して一覧表示する。
/// 計算は initState で1回だけ行い、build では再計算しない。
class SupportSimulationScreen extends StatefulWidget {
  /// 試算対象の候補者リスト
  final List<Candidate> candidates;

  /// 現在の社会状態
  final SocietyState society;

  /// 直近の選挙（あれば履歴ふまえの予測になる）
  final Election? lastElection;

  /// プレイヤー（試算には直接使わないが将来の拡張用に保持）
  final Citizen? player;

  /// 表示タイトル（未指定なら lastElection のタイトル）
  final String? electionTitle;

  /// 有権者の上書き（未指定ならデフォルトの有権者10人）
  final List<Citizen>? votersOverride;

  const SupportSimulationScreen({
    super.key,
    required this.candidates,
    required this.society,
    this.lastElection,
    this.player,
    this.electionTitle,
    this.votersOverride,
  });

  @override
  State<SupportSimulationScreen> createState() =>
      _SupportSimulationScreenState();
}

class _SupportSimulationScreenState extends State<SupportSimulationScreen> {
  /// initState で一度だけ計算した試算結果
  late final SupportSimulation _simulation;

  /// candidateId → 支持の厚い職業（initState で一度だけ計算）
  late final Map<String, Job> _topJobs;

  @override
  void initState() {
    super.initState();
    _simulation = SupportSimulationService.compute(
      candidates: widget.candidates,
      society: widget.society,
      lastElection: widget.lastElection,
      voters: widget.votersOverride,
      title: widget.electionTitle ?? widget.lastElection?.title,
    );
    _topJobs = SupportSimulationService.topJobPerCandidate(
      candidates: widget.candidates,
      society: widget.society,
      lastElection: widget.lastElection,
      voters: widget.votersOverride,
    );
  }

  @override
  Widget build(BuildContext context) {
    final simulation = _simulation;
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: Semantics(
          key: AppKeys.supportTitle,
          header: true,
          label: '支持率シミュレーション',
          child: const Text('支持率シミュレーション'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 空状態: 候補者がいなければ試算できない
              if (simulation.isEmpty)
                const Center(
                  child: Text(
                    '候補者がいないため試算できません',
                    key: AppKeys.supportEmptyState,
                    style: TextStyle(color: RetroPalette.textNormal),
                  ),
                )
              else ...[
                // 世論カード
                _MoodCard(simulation: simulation),
                const SizedBox(height: 16),
                // 首位カード
                if (simulation.leader != null)
                  _LeaderCard(
                    leader: simulation.leader!,
                    hasHistory: simulation.hasHistory,
                  ),
                const SizedBox(height: 16),
                // 候補者一覧
                for (final snapshot in simulation.snapshots)
                  _CandidateRow(
                    snapshot: snapshot,
                    topJob: _topJobs[snapshot.candidateId],
                  ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              // 脚注
              const Text(
                '職業×政策の親和性・現職の公約達成度・世論の頑固さから試算した参考値です',
                key: AppKeys.supportNote,
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

/// 世論カード: 世論の傾向・頑固さ・有権者数を表示。
class _MoodCard extends StatelessWidget {
  final SupportSimulation simulation;

  const _MoodCard({required this.simulation});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AppKeys.supportMoodCard,
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '世論',
            style: TextStyle(
              color: RetroPalette.panelBorder,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '世論の傾向: ${simulation.moodLabel}',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '有権者の頑固さ: ${simulation.stubbornnessLabel}',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '${simulation.voterCount}人の有権者で試算',
            key: AppKeys.supportVoterCount,
            style: const TextStyle(
              color: RetroPalette.voteAbstain,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 首位カード: 現在の支持率首位候補を強調表示。
class _LeaderCard extends StatelessWidget {
  final SupportSnapshot leader;
  final bool hasHistory;

  const _LeaderCard({required this.leader, required this.hasHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AppKeys.supportLeaderCard,
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.gold),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '現在の首位',
            style: TextStyle(
              color: RetroPalette.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  leader.candidateName,
                  style: const TextStyle(
                    color: RetroPalette.textAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                leader.supportPercentLabel,
                style: const TextStyle(
                  color: RetroPalette.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasHistory ? '過去選挙の実績をふまえた予測' : '今回が初回の選挙',
            style: const TextStyle(
              color: RetroPalette.textNormal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 候補者1人分の行: 名前・支持率バー・割合・支持の厚い職業層。
class _CandidateRow extends StatelessWidget {
  final SupportSnapshot snapshot;
  final Job? topJob;

  const _CandidateRow({required this.snapshot, required this.topJob});

  @override
  Widget build(BuildContext context) {
    final job = topJob;
    return Container(
      key: AppKeys.supportCandidateRow(snapshot.candidateId),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.candidateName,
            style: const TextStyle(
              color: RetroPalette.textAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: snapshot.supportRate.clamp(0.0, 1.0),
            backgroundColor: RetroPalette.bgDark,
            color: RetroPalette.gold,
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Text(
            snapshot.supportPercentLabel,
            key: AppKeys.supportCandidateRate(snapshot.candidateId),
            style: const TextStyle(color: RetroPalette.textNormal, fontSize: 12),
          ),
          if (job != null)
            Text(
              '${job.label}層の支持が厚い',
              key: AppKeys.supportCandidateJob(snapshot.candidateId),
              style: const TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
