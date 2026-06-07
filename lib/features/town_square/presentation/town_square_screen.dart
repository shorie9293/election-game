import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen_npc_relationship.dart';
import 'package:election_game/domain/models/opposition_citizen.dart';

/// 街の広場画面 — NPCと会話できる
class TownSquareScreen extends StatelessWidget {
  final List<OppositionCitizen> npcs;
  final double societyMood;
  final Map<String, CitizenNpcRelationship> npcRelationships;
  final ValueChanged<String>? onNpcInteract;

  const TownSquareScreen({
    super.key,
    required this.npcs,
    required this.societyMood,
    this.npcRelationships = const {},
    this.onNpcInteract,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: Semantics(
          key: AppKeys.townSquareTitle,
          header: true,
          label: '街の広場',
          child: const Text('街の広場'),
        ),
      ),
      body: SemanticHelper.interactive(
        testId: 'btn_town_square_npc_list',
        label: 'NPC一覧',
        child: SingleChildScrollView(
          key: AppKeys.townSquareNpcList,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: npcs.map((npc) => _NpcCard(
              npc: npc,
              societyMood: societyMood,
              relationship: npcRelationships[npc.id],
              onNpcInteract: onNpcInteract,
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class _NpcCard extends StatelessWidget {
  final OppositionCitizen npc;
  final double societyMood;
  final CitizenNpcRelationship? relationship;
  final ValueChanged<String>? onNpcInteract;

  const _NpcCard({
    required this.npc,
    required this.societyMood,
    this.relationship,
    this.onNpcInteract,
  });

  String _candidateHint(String? candidateId) {
    if (candidateId == null) return '未定';
    final candidates = Candidate.samples();
    for (final c in candidates) {
      if (c.id == candidateId) {
        return '${c.faction}・${c.name}を支持';
      }
    }
    return candidateId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showDebateSheet(context),
        child: Container(
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
                      color: RetroPalette.panelBorder.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: RetroPalette.textAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          npc.name,
                          style: const TextStyle(
                            color: RetroPalette.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          npc.job.label,
                          style: const TextStyle(
                            color: RetroPalette.textNormal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '性格: ${npc.personality}',
                style: const TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _candidateHint(npc.supportedCandidateId),
                style: const TextStyle(
                  color: RetroPalette.textAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDebateSheet(BuildContext context) {
    // Trigger interaction callback
    onNpcInteract?.call(npc.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: RetroPalette.panelBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: RetroPalette.panelBorder),
      ),
      builder: (sheetContext) {
        return _NpcConversationSheet(
          npc: npc,
          societyMood: societyMood,
          relationship: relationship,
        );
      },
    );
  }
}

/// NPCとの会話・議論用のボトムシート内容
class _NpcConversationSheet extends StatefulWidget {
  final OppositionCitizen npc;
  final double societyMood;
  final CitizenNpcRelationship? relationship;

  const _NpcConversationSheet({
    required this.npc,
    required this.societyMood,
    this.relationship,
  });

  @override
  State<_NpcConversationSheet> createState() => _NpcConversationSheetState();
}

class _NpcConversationSheetState extends State<_NpcConversationSheet> {
  bool _showDebateOptions = false;
  int? _selectedReplyIndex;

  OppositionCitizen get npc => widget.npc;
  double get societyMood => widget.societyMood;

  String get _currentMoodLabel {
    if (societyMood < 0.2) return 'なれ合い';
    if (societyMood < 0.4) return '融和';
    if (societyMood < 0.6) return '健全な対立';
    if (societyMood < 0.8) return '不健全な対立';
    return '独裁';
  }

  String _candidateHint(String? candidateId) {
    if (candidateId == null) return '未定';
    final candidates = Candidate.samples();
    for (final c in candidates) {
      if (c.id == candidateId) {
        return '${c.faction}・${c.name}';
      }
    }
    return candidateId;
  }

  @override
  Widget build(BuildContext context) {
    final dialogText = npc.dialogs.getDialogForMood(societyMood);
    final debateOptions = npc.dialogs.getDebateReplies(societyMood);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              _buildHeader(),
              const SizedBox(height: 16),

              // --- Greeting ---
              _buildGreeting(),
              const SizedBox(height: 12),

              // --- Mood dialog ---
              _buildMoodDialog(dialogText),
              const SizedBox(height: 16),
              const Divider(color: RetroPalette.panelBorder, height: 1),
              const SizedBox(height: 16),

              // --- NPC Info ---
              _buildNpcInfo(),
              const SizedBox(height: 20),

              // --- Debate Section ---
              _buildDebateSection(debateOptions),
              const SizedBox(height: 20),

              // --- Close button ---
              _buildCloseButton(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RetroPalette.panelBorder.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.person,
            size: 24,
            color: RetroPalette.textAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                npc.name,
                style: const TextStyle(
                  color: RetroPalette.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${npc.job.label}　性格: ${npc.personality}',
                style: const TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Greeting ──
  Widget _buildGreeting() {
    final relationship = widget.relationship;
    final greetingText = relationship != null
        ? widget.npc.dialogs.getRelationshipGreeting(relationship.relationship)
        : widget.npc.dialogs.greeting;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RetroPalette.bgDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: RetroPalette.panelBorder.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greetingText,
            style: const TextStyle(
              color: RetroPalette.textAccent,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (relationship != null && relationship.interactionCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '（会話回数: ${relationship.interactionCount}回）',
              style: TextStyle(
                color: RetroPalette.textNormal.withAlpha(150),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mood dialog ──
  Widget _buildMoodDialog(String dialogText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RetroPalette.panelBorder.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBorder.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '社会の空気: $_currentMoodLabel',
                  style: const TextStyle(
                    color: RetroPalette.panelBorder,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dialogText,
            style: const TextStyle(
              color: RetroPalette.textNormal,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── NPC Info ──
  Widget _buildNpcInfo() {
    final supportedInfo = _candidateHint(npc.supportedCandidateId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RetroPalette.bgDark.withAlpha(150),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: RetroPalette.panelBorder.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'NPC情報',
            style: TextStyle(
              color: RetroPalette.gold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Supported candidate
          Row(
            children: [
              const Icon(Icons.how_to_vote, size: 14, color: RetroPalette.textAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '支持: $supportedInfo',
                  style: const TextStyle(
                    color: RetroPalette.textAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stubbornness bar
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 14, color: RetroPalette.warning),
              const SizedBox(width: 6),
              const Text(
                '頑固さ:',
                style: TextStyle(color: RetroPalette.textNormal, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: npc.stubbornness,
                    backgroundColor: RetroPalette.bgDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      RetroPalette.warning,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(npc.stubbornness * 100).toInt()}%',
                style: const TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Debate topics
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: npc.debateTopics.map((topic) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBorder.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: RetroPalette.panelBorder.withAlpha(60),
                  ),
                ),
                child: Text(
                  topic.label,
                  style: const TextStyle(
                    color: RetroPalette.panelBorder,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Debate Section ──
  Widget _buildDebateSection(List<String> debateOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            const Icon(Icons.forum, size: 16, color: RetroPalette.panelBorder),
            const SizedBox(width: 6),
            const Text(
              '議論',
              style: TextStyle(
                color: RetroPalette.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (debateOptions.isEmpty)
          // No debate options available
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RetroPalette.bgDark,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '今の社会の空気では議論できそうにない…',
              style: TextStyle(
                color: RetroPalette.textNormal.withAlpha(150),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else ...[
          if (_selectedReplyIndex != null) ...[
            // Show player's selected option
            _buildSpeechBubble(
              message: debateOptions[_selectedReplyIndex!],
              isPlayer: true,
            ),
            const SizedBox(height: 8),
            // Show NPC reply
            _buildSpeechBubble(
              message: _getNpcReply(debateOptions[_selectedReplyIndex!]),
              isPlayer: false,
            ),
            const SizedBox(height: 12),
            // Continue debate button
            _buildDebateButton('さらに議論する', debateOptions),
          ] else if (_showDebateOptions) ...[
            // Show debate options
            const Text(
              'あなたの主張を選んでください:',
              style: TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ...debateOptions.asMap().entries.map((entry) {
              final idx = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDebateOptionButton(idx, option, debateOptions),
              );
            }),
          ] else ...[
            // Initial state: show "議論する" button
            _buildStartDebateButton(),
          ],
        ],
      ],
    );
  }

  Widget _buildSpeechBubble({required String message, required bool isPlayer}) {
    return Align(
      alignment: isPlayer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPlayer
              ? RetroPalette.panelBorder.withAlpha(40)
              : RetroPalette.bgDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isPlayer
                ? const Radius.circular(12)
                : const Radius.circular(4),
            bottomRight: isPlayer
                ? const Radius.circular(4)
                : const Radius.circular(12),
          ),
          border: Border.all(
            color: isPlayer
                ? RetroPalette.panelBorder.withAlpha(100)
                : RetroPalette.panelBorder.withAlpha(60),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPlayer ? 'あなた' : npc.name,
              style: TextStyle(
                color: isPlayer ? RetroPalette.gold : RetroPalette.textAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartDebateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _showDebateOptions = true;
          });
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('議論する'),
        style: ElevatedButton.styleFrom(
          backgroundColor: RetroPalette.panelBorder,
          foregroundColor: RetroPalette.bgDark,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildDebateOptionButton(
    int index,
    String option,
    List<String> allOptions,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedReplyIndex = index;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: RetroPalette.textAccent,
          side: const BorderSide(color: RetroPalette.panelBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          option,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildDebateButton(String label, List<String> debateOptions) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _selectedReplyIndex = null;
            _showDebateOptions = true;
          });
        },
        icon: const Icon(Icons.refresh, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: RetroPalette.panelBorder,
          side: const BorderSide(color: RetroPalette.panelBorder),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        key: AppKeys.townSquareCloseButton,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(
          '閉じる',
          style: TextStyle(
            color: RetroPalette.panelBorder,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Get NPC's reply to the player's selected debate option.
  /// This uses a simple counter-response heuristic based on the debate option index.
  String _getNpcReply(String playerChoice) {
    // Get the debate replies for current mood
    final allReplies = npc.dialogs.getDebateReplies(societyMood);
    if (allReplies.isEmpty) return '……（無言で考え込んでいる）';

    // Pick a different reply from the same mood pool as a response
    // Simple heuristic: use the last reply in the pool as counter-argument
    final responsePool = allReplies.where((r) => r != playerChoice).toList();
    if (responsePool.isNotEmpty) {
      return responsePool.last;
    }
    return allReplies.first;
  }
}
