import 'package:flutter/material.dart';
import 'package:election_game/core/accessibility/semantic_helper.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';

/// 投票画面 — 候補者を選んで一票を投じる
class VoteScreen extends StatefulWidget {
  final List<Candidate> candidates;
  final ValueChanged<String>? onVote;

  const VoteScreen({
    super.key,
    required this.candidates,
    this.onVote,
  });

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('投票所')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RetroPalette.panelBg,
              border: const Border(
                bottom: BorderSide(color: RetroPalette.panelBorder, width: 2),
              ),
            ),
            child: const Text(
              '一票を投じよ',
              key: AppKeys.voteTitle,
              style: TextStyle(
                fontSize: 20,
                color: RetroPalette.panelBorder,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              key: AppKeys.voteCandidateList,
              padding: const EdgeInsets.all(16),
              itemCount: widget.candidates.length,
              itemBuilder: (context, index) {
                final c = widget.candidates[index];
                final isSelected = _selectedId == c.id;
                return SemanticHelper.interactive(
                  key: Key('vote_candidate_${c.id}'),
                  label: '${c.name} に投票',
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedId = c.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? RetroPalette.gold.withValues(alpha: 0.15)
                            : RetroPalette.panelBg,
                        border: Border.all(
                          color:
                              isSelected ? RetroPalette.gold : RetroPalette.panelBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? RetroPalette.gold
                                  : RetroPalette.bgDark,
                            ),
                            child: isSelected
                                ? const Icon(Icons.how_to_vote,
                                    color: RetroPalette.bgDark, size: 20)
                                : const Icon(Icons.person_outline,
                                    color: RetroPalette.textAccent,
                                    size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? RetroPalette.gold
                                        : RetroPalette.textNormal,
                                  ),
                                ),
                                Text(
                                  c.faction,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: RetroPalette.textAccent,
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
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SemanticHelper.interactive(
              key: AppKeys.voteConfirmButton,
              label: '投票する',
              button: true,
              child: ElevatedButton(
                onPressed: _selectedId != null && widget.onVote != null
                    ? () => widget.onVote!(_selectedId!)
                    : null,
                child: const Text(
                  'この一票を投じる',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
