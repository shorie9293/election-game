import 'package:flutter/material.dart';
import 'package:election_game/core/accessibility/semantic_helper.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';

/// 新聞風 開票結果画面
class ResultScreen extends StatelessWidget {
  final Election election;
  final SocietyState previousSociety;
  final SocietyState newSociety;
  final Map<String, int> oldLifeParams;
  final Map<String, int> newLifeParams;
  final VoidCallback? onContinue;

  const ResultScreen({
    super.key,
    required this.election,
    required this.previousSociety,
    required this.newSociety,
    required this.oldLifeParams,
    required this.newLifeParams,
    this.onContinue,
  });

  static const _paramLabels = {
    'lifeCost': '生活費',
    'healthcare': '医療',
    'education': '教育',
    'employment': '仕事',
    'environment': '環境',
    'safety': '治安',
  };

  Candidate? get _winner {
    if (election.winnerId == null) return null;
    try {
      return election.candidates
          .firstWhere((c) => c.id == election.winnerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final winner = _winner;

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('号外！開票結果')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Winner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: RetroPalette.gold, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  const Text(
                    '当選',
                    key: AppKeys.resultTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: RetroPalette.textAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winner?.name ?? 'なし',
                    key: AppKeys.resultWinner,
                    style: const TextStyle(
                      fontSize: 24,
                      color: RetroPalette.gold,
                    ),
                  ),
                  if (winner != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      winner.faction,
                      style: const TextStyle(
                        fontSize: 14,
                        color: RetroPalette.textAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Vote counts
            ...election.candidates.map((c) {
              final votes =
                  election.voteCounts?[c.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: c.id == election.winnerId
                              ? RetroPalette.gold
                              : RetroPalette.textNormal,
                        ),
                      ),
                    ),
                    Text(
                      '$votes票',
                      style: const TextStyle(
                        fontSize: 13,
                        color: RetroPalette.gold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            // Life impact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: RetroPalette.panelBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  const Text(
                    'あなたの生活への影響',
                    key: AppKeys.resultLifeImpact,
                    style: TextStyle(
                      fontSize: 16,
                      color: RetroPalette.panelBorder,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._paramLabels.entries.map((e) {
                    final old = oldLifeParams[e.key] ?? 0;
                    final newVal = newLifeParams[e.key] ?? 0;
                    final delta = newVal - old;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 12,
                              color: RetroPalette.textNormal,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '$newVal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: RetroPalette.gold,
                                ),
                              ),
                              if (delta != 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  delta > 0 ? '↑$delta' : '↓${-delta}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: delta > 0
                                        ? RetroPalette.success
                                        : RetroPalette.danger,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Mood change
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: RetroPalette.panelBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  const Text(
                    '社会の空気',
                    style: TextStyle(
                      fontSize: 14,
                      color: RetroPalette.panelBorder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        previousSociety.moodLabel,
                        style: TextStyle(
                          fontSize: 16,
                          color: RetroPalette.textAccent,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '→',
                          style: TextStyle(
                            fontSize: 20,
                            color: RetroPalette.gold,
                          ),
                        ),
                      ),
                      Text(
                        newSociety.moodLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          color: RetroPalette.panelBorder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SemanticHelper.interactive(
              key: AppKeys.resultContinueButton,
              label: '次へ進む',
              button: true,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('自宅に戻る'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
