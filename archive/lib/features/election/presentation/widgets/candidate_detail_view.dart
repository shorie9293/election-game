import 'package:flutter/material.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';

/// 候補者詳細表示（公約一覧）
class CandidateDetailView extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onBack;

  const CandidateDetailView({
    super.key,
    required this.candidate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            candidate.name,
            key: AppKeys.candidateDetailTitle,
            style: const TextStyle(
              fontSize: 20,
              color: RetroPalette.panelBorder,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${candidate.faction} ／ ${candidate.personality}',
            style: const TextStyle(
              fontSize: 14,
              color: RetroPalette.textAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            '公約',
            style: TextStyle(
              fontSize: 16,
              color: RetroPalette.panelBorder,
            ),
          ),
          const SizedBox(height: 8),
          ...candidate.policies.map((p) => Container(
                key: AppKeys.candidatePolicies,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border:
                      Border.all(color: RetroPalette.panelBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: RetroPalette.panelBorder,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RetroPalette.textNormal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.effects.entries
                          .map((e) =>
                              '${e.key}: ${e.value > 0 ? "+" : ""}${e.value}')
                          .join(', '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: RetroPalette.textAccent,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Text(
            '支持団体: ${candidate.faction}',
            key: AppKeys.candidateSupportGroup,
            style: const TextStyle(
              fontSize: 12,
              color: RetroPalette.textAccent,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('候補者一覧に戻る'),
          ),
        ],
      ),
    );
  }
}
