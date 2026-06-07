import 'package:flutter/material.dart';
import 'package:election_game/core/accessibility/semantic_helper.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/election/presentation/widgets/candidate_detail_view.dart';

/// 新聞風 選挙告示画面
class ElectionAnnouncementScreen extends StatefulWidget {
  final Election election;
  final SocietyState society;
  final VoidCallback? onProceed;

  const ElectionAnnouncementScreen({
    super.key,
    required this.election,
    required this.society,
    this.onProceed,
  });

  @override
  State<ElectionAnnouncementScreen> createState() =>
      _ElectionAnnouncementScreenState();
}

class _ElectionAnnouncementScreenState
    extends State<ElectionAnnouncementScreen> {
  Candidate? _selectedCandidate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('号外！選挙告示')),
      body: _selectedCandidate != null
          ? CandidateDetailView(
              candidate: _selectedCandidate!,
              onBack: () => setState(() => _selectedCandidate = null),
            )
          : _buildCandidateList(),
    );
  }

  Widget _buildCandidateList() {
    return Column(
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
          child: Column(
            children: [
              Text(
                widget.election.title,
                key: AppKeys.newspaperTitle,
                style: const TextStyle(
                  fontSize: 20,
                  color: RetroPalette.panelBorder,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '社会の空気：${widget.society.moodLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  color: RetroPalette.textAccent,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: AppKeys.newspaperCandidateList,
            padding: const EdgeInsets.all(12),
            itemCount: widget.election.candidates.length,
            itemBuilder: (context, index) {
              final c = widget.election.candidates[index];
              return SemanticHelper.interactive(
                key: Key('candidate_${c.id}'),
                label: '候補者 ${c.name}',
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCandidate = c),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RetroPalette.panelBg,
                      border: Border.all(color: RetroPalette.panelBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: RetroPalette.bgDark,
                                border: Border.all(
                                    color: RetroPalette.panelBorder),
                              ),
                              child: const Icon(Icons.person,
                                  color: RetroPalette.textAccent, size: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: RetroPalette.panelBorder,
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
                        const SizedBox(height: 8),
                        Text(
                          c.personality,
                          style: const TextStyle(
                            fontSize: 13,
                            color: RetroPalette.textNormal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '公約: ${c.policies.map((p) => p.title).join("、")}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: RetroPalette.textAccent,
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
            key: AppKeys.newspaperProceedButton,
            label: '投票所へ進む',
            button: true,
            child: ElevatedButton(
              onPressed: widget.onProceed,
              child: const Text('投票所へ進む'),
            ),
          ),
        ),
      ],
    );
  }

}
