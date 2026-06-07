import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';

/// 選挙告示画面（候補者一覧表示）
/// 段階（村・町・市）に応じたコンテキスト表示をサポート
class ElectionAnnouncementScreen extends StatelessWidget {
  final Election election;
  final VoidCallback? onProceed;

  const ElectionAnnouncementScreen({
    super.key,
    required this.election,
    this.onProceed,
  });

  /// スケールに応じた説明テキスト
  String get _scaleContext {
    switch (election.scale) {
      case ElectionScale.village:
        return '小さな村のリーダーを決める大切な選挙です。\n村人は皆、顔見知りです。';
      case ElectionScale.town:
        return '町としての成長が進む中、\nより多くの課題に取り組むリーダーが求められています。';
      case ElectionScale.city:
        return '大都市としての発展を担う\n経験豊富なリーダーが必要です。';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: Text(election.scale.title),
      ),
      body: Column(
        children: [
          // ヘッダー
          SemanticHelper.interactive(
            testId: 'btn_election_announce_title',
            label: '選挙告示',
            child: Container(
              key: AppKeys.electionAnnounceTitle,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: RetroPalette.panelBg,
              child: Column(
                children: [
                  const Icon(Icons.campaign, color: RetroPalette.gold, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    election.title,
                    style: const TextStyle(
                      color: RetroPalette.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '立候補者: ${election.candidates.length}名',
                    style: const TextStyle(color: RetroPalette.textAccent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scaleContext,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RetroPalette.textNormal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 候補者リスト
          Expanded(
            child: SemanticHelper.interactive(
              testId: 'btn_candidate_list',
              label: '候補者一覧',
              child: ListView(
                key: AppKeys.electionCandidateList,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: election.candidates.map((candidate) {
                  return _CandidateCard(candidate: candidate);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 次へ進むボタン
          Padding(
            padding: const EdgeInsets.all(16),
            child: SemanticHelper.interactive(
              testId: 'btn_proceed_to_vote_from_announce',
              label: '候補者を見て投票所へ',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: AppKeys.electionProceedButton,
                  onPressed: onProceed,
                  child: const Text('公約を見て投票へ'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Candidate candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RetroPalette.bgDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: RetroPalette.textAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        color: RetroPalette.gold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${candidate.faction} · ${candidate.personality}',
                      style: const TextStyle(
                        color: RetroPalette.textAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: RetroPalette.panelBorder),
          const SizedBox(height: 4),
          ...candidate.policies.map((policy) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: RetroPalette.success),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${policy.title}: ${policy.description}',
                      style: const TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
