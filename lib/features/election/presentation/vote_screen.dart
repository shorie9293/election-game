import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';

/// 投票画面
class VoteScreen extends StatefulWidget {
  final Election election;
  final void Function(String candidateId)? onVoteCast;
  final VoidCallback? onAbstain;

  const VoteScreen({
    super.key,
    required this.election,
    this.onVoteCast,
    this.onAbstain,
  });

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String? _selectedCandidateId;

  void _confirmVote() {
    if (_selectedCandidateId != null) {
      widget.onVoteCast?.call(_selectedCandidateId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('投票所'),
      ),
      body: Column(
        children: [
          // ヘッダー
          SemanticHelper.interactive(
            testId: 'btn_vote_title',
            label: '投票',
            child: Container(
              key: AppKeys.voteTitle,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: RetroPalette.panelBg,
              child: const Column(
                children: [
                  Icon(Icons.how_to_vote, color: RetroPalette.gold, size: 48),
                  SizedBox(height: 8),
                  Text(
                    '一票を投じましょう',
                    style: TextStyle(
                      color: RetroPalette.gold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 候補者リスト
          Expanded(
            child: SemanticHelper.interactive(
              testId: 'btn_vote_candidate_list',
              label: '投票候補者一覧',
              child: ListView.builder(
                key: AppKeys.voteCandidateList,
                padding: const EdgeInsets.all(16),
                itemCount: widget.election.candidates.length,
                itemBuilder: (context, index) {
                  final candidate = widget.election.candidates[index];
                  final isSelected = _selectedCandidateId == candidate.id;
                  return _VoteCandidateCard(
                    candidate: candidate,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedCandidateId = candidate.id);
                    },
                  );
                },
              ),
            ),
          ),

          // ボタン群
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 確定投票
                if (_selectedCandidateId != null)
                  SemanticHelper.interactive(
                    testId: 'btn_vote_confirm',
                    label: '投票を確定',
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: AppKeys.voteConfirmButton,
                        onPressed: _confirmVote,
                        child: const Text('投票する'),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // 棄権
                SemanticHelper.interactive(
                  testId: 'btn_vote_abstain',
                  label: '棄権',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: AppKeys.voteAbstainButton,
                      onPressed: widget.onAbstain,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RetroPalette.voteAbstain,
                        side: const BorderSide(color: RetroPalette.voteAbstain),
                      ),
                      child: const Text('棄権する'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteCandidateCard extends StatelessWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onTap;

  const _VoteCandidateCard({
    required this.candidate,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? RetroPalette.gold.withAlpha(30)
                : RetroPalette.panelBg,
            border: Border.all(
              color: isSelected ? RetroPalette.gold : RetroPalette.panelBorder,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: candidate.id,
                groupValue: isSelected ? candidate.id : null,
                onChanged: (_) => onTap(),
                activeColor: RetroPalette.gold,
              ),
              const SizedBox(width: 8),
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
                      candidate.faction,
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
        ),
      ),
    );
  }
}
