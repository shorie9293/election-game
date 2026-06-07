import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/concern_evolution.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/services/narrative_service.dart';

/// 選挙結果画面
class ElectionResultScreen extends StatelessWidget {
  final Election result;
  final Map<String, int> lifeParamChanges;
  final VoidCallback? onContinue;
  final String? votedCandidateId;
  final bool abstained;
  final List<ConcernEvolution> concernEvolutions;

  const ElectionResultScreen({
    super.key,
    required this.result,
    required this.lifeParamChanges,
    this.onContinue,
    this.votedCandidateId,
    this.abstained = false,
    this.concernEvolutions = const [],
  });

  Candidate? get _winner {
    if (result.winnerId == null) return null;
    return result.candidates.firstWhere(
      (c) => c.id == result.winnerId,
    );
  }

  Candidate? get _votedCandidate {
    if (votedCandidateId == null) return null;
    return result.candidates.firstWhere(
      (c) => c.id == votedCandidateId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = _winner;
    final voted = _votedCandidate;
    final narrative = NarrativeService.generateNarrative(
      result, votedCandidateId, abstained,
    );
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('開票結果'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 結果ヘッダー
            SemanticHelper.interactive(
              testId: 'btn_result_title',
              label: '選挙結果',
              child: Container(
                key: AppKeys.resultTitle,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.gold),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.celebration, color: RetroPalette.gold, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      '開票結果',
                      style: TextStyle(
                        color: RetroPalette.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (winner != null)
                      SemanticHelper.interactive(
                        testId: 'btn_result_winner',
                        label: '当選者: ${winner.name}',
                        child: Text(
                          key: AppKeys.resultWinner,
                          '当選: ${winner.name} 氏',
                          style: const TextStyle(
                            color: RetroPalette.textNormal,
                            fontSize: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 得票数
            if (result.voteCounts != null)
              SemanticHelper.interactive(
                testId: 'btn_result_vote_counts',
                label: '得票数',
                child: Container(
                  key: AppKeys.resultVoteCounts,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RetroPalette.panelBg,
                    border: Border.all(color: RetroPalette.panelBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '得票数',
                        style: TextStyle(color: RetroPalette.textAccent, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ...result.voteCounts!.entries.map((entry) {
                        final candidate = result.candidates.firstWhere(
                          (c) => c.id == entry.key,
                        );
                        final isWinner = entry.key == result.winnerId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              if (isWinner)
                                const Icon(Icons.star, color: RetroPalette.gold, size: 16),
                              if (isWinner) const SizedBox(width: 4),
                              Text(
                                '${candidate.name}: ${entry.value}票',
                                style: TextStyle(
                                  color: isWinner
                                      ? RetroPalette.gold
                                      : RetroPalette.textNormal,
                                  fontWeight:
                                      isWinner ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 当選者スピーチ
            if (narrative.winnerSpeech.isNotEmpty)
              SemanticHelper.interactive(
                testId: 'btn_result_winner_speech',
                label: '当選者スピーチ',
                child: Container(
                  key: AppKeys.resultWinnerSpeech,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RetroPalette.panelBg,
                    border: Border.all(color: RetroPalette.gold),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.mic, color: RetroPalette.gold, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '🎤 当選者スピーチ',
                            style: TextStyle(
                              color: RetroPalette.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        narrative.winnerSpeech,
                        style: const TextStyle(
                          color: RetroPalette.textNormal,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // NPCの反応
            if (narrative.npcReactions.isNotEmpty)
              SemanticHelper.interactive(
                testId: 'btn_result_npc_reactions',
                label: '市民の反応',
                child: Container(
                  key: AppKeys.resultNpcReactions,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RetroPalette.panelBg,
                    border: Border.all(color: RetroPalette.panelBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people, color: RetroPalette.textAccent, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '🗣️ 街の声',
                            style: TextStyle(
                              color: RetroPalette.textAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...narrative.npcReactions.map((reaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          reaction,
                          style: const TextStyle(
                            color: RetroPalette.textNormal,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // あなたの投票と因果関係
            SemanticHelper.interactive(
              testId: 'btn_result_vote_explanation',
              label: 'あなたの投票の影響',
              child: Container(
                key: AppKeys.resultVoteExplanation,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.panelBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📮 あなたの投票',
                      style: TextStyle(color: RetroPalette.textAccent, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (abstained) ...[
                      const Text(
                        'あなたは棄権しました。\n棄権により、あなたの意思は今回の選挙結果に\n反映されませんでした。',
                        style: TextStyle(color: RetroPalette.textNormal, fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '💡 ヒント: 投票に行くことで、あなたの生活に\n関わる政策の行方に影響を与えられます。',
                        style: TextStyle(color: RetroPalette.textAccent, fontSize: 12, height: 1.5),
                      ),
                    ] else ...[
                      if (voted != null) ...[
                        Text(
                          '${voted.name} 氏（${voted.faction}）に投票しました。',
                          style: const TextStyle(color: RetroPalette.textNormal, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'この候補者の主な公約:',
                          style: TextStyle(color: RetroPalette.textAccent, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        ...voted.policies.map((p) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            '・${p.title}: ${p.description}',
                            style: const TextStyle(color: RetroPalette.textNormal, fontSize: 12, height: 1.4),
                          ),
                        )),
                      ],
                      const SizedBox(height: 12),
                      if (winner != null && voted != null) ...[
                        if (winner.id == voted.id) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RetroPalette.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '✨ あなたが投票した候補者が当選しました！\nあなたの一票が結果に反映されています。',
                              style: TextStyle(color: RetroPalette.success, fontSize: 13, height: 1.5),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RetroPalette.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'あなたの投票した候補者は当選しませんでしたが、\n当選した${winner.name}氏の政策があなたの生活に影響します。',
                              style: const TextStyle(color: RetroPalette.warning, fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 生活パラメータ変化
            if (lifeParamChanges.isNotEmpty)
              SemanticHelper.interactive(
                testId: 'btn_result_life_impact',
                label: '生活への影響',
                child: Container(
                  key: AppKeys.resultLifeImpact,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RetroPalette.panelBg,
                    border: Border.all(color: RetroPalette.panelBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'あなたの生活への影響',
                        style: TextStyle(color: RetroPalette.textAccent, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ...lifeParamChanges.entries.map((entry) {
                        final isPositive = entry.value >= 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                color: isPositive
                                    ? RetroPalette.success
                                    : RetroPalette.danger,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${LifeParamKeys.label(entry.key)}: ${isPositive ? "+" : ""}${entry.value}',
                                style: TextStyle(
                                  color: isPositive
                                      ? RetroPalette.success
                                      : RetroPalette.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      if (winner != null) ...[
                        const Divider(),
                        const SizedBox(height: 4),
                        Text(
                          '当選者 ${winner.name} 氏の政策による影響です。',
                          style: const TextStyle(color: RetroPalette.textAccent, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 関心事の成長（選挙後に新たな関心が芽生えた場合）
            if (concernEvolutions.any((e) => e.isAcquired)) ...[
              SemanticHelper.interactive(
                testId: 'btn_result_concern_growth',
                label: '関心事の成長',
                child: Container(
                  key: AppKeys.resultConcernGrowth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RetroPalette.panelBg,
                    border: Border.all(
                      color: RetroPalette.gold.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: RetroPalette.gold, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            '政治的成長',
                            style: TextStyle(
                              color: RetroPalette.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '+${concernEvolutions.where((e) => e.isAcquired).length}',
                            style: const TextStyle(
                              color: RetroPalette.textAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...concernEvolutions
                          .where((e) => e.isAcquired)
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.concern.label,
                                      style: const TextStyle(
                                        color: RetroPalette.textNormal,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        e.reason,
                                        style: const TextStyle(
                                          color: RetroPalette.voteAbstain,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 続けるボタン
            SemanticHelper.interactive(
              testId: 'btn_return_to_town',
              label: '街に戻る',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: AppKeys.resultContinueButton,
                  onPressed: onContinue,
                  child: const Text('街に戻る'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
