import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/candidate_rating.dart';
import 'package:election_game/domain/models/debate_reaction.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/services/rating_service.dart';

/// 討論会の発言1つを表すモデル
class DebateLine {
  final String speakerName;
  final String text;
  final String? faction;

  const DebateLine({
    required this.speakerName,
    required this.text,
    this.faction,
  });
}

/// 討論会画面（候補者討論→市民反応→候補者評価→投票）
///
/// 各候補者の発言の後にプレイヤーの反応（同意/反対/質問/沈黙）を選択する。
/// 全発言終了後、各候補者を1〜5星で評価し、投票へ進む。
class DebateScreen extends StatefulWidget {
  final Election election;
  final VoidCallback onProceedToVote;

  const DebateScreen({
    super.key,
    required this.election,
    required this.onProceedToVote,
  });

  /// 候補者リストから討論の発言を生成する
  static List<DebateLine> generateDebateLines(List<Candidate> candidates) {
    final lines = <DebateLine>[];
    final n = candidates.length;

    if (n < 2) {
      for (final c in candidates) {
        lines.add(DebateLine(
          speakerName: c.name,
          text: '私の公約は「${c.policies.first.title}」です。',
          faction: c.faction,
        ));
      }
      return lines;
    }

    final totalLines = n == 2 ? 4 : 6;

    for (int i = 0; i < totalLines; i++) {
      final candidate = candidates[i % n];
      final speakerName = candidate.name;
      final faction = candidate.faction;
      final policy = candidate.policies.isNotEmpty
          ? candidate.policies[i % candidate.policies.length]
          : null;

      String text;
      if (i % n == 0) {
        if (policy != null) {
          text = '私の公約は「${policy.title}」です。'
              '${policy.description}で皆様の生活を必ず良くします！';
        } else {
          text = '私の公約で皆様の生活を必ず良くします！';
        }
      } else if (i % n == 1) {
        final opponent = candidates[(i + 1) % n];
        text = '${opponent.name}さんの案は理想論です。'
            '私の現実的な政策で確実に成果を出します。';
      } else {
        final texts = [
          '税金の無駄遣いをなくし、本当に必要なところに予算を回します。',
          '地域の声に耳を傾け、住民参加型の政治を実現します。',
          '教育と医療の充実こそが町の未来への投資です。',
          '持続可能な開発で次の世代に誇れる町を残します。',
          '汚職のない透明な政治を約束します。',
        ];
        text = texts[i % texts.length];
      }

      lines.add(DebateLine(
        speakerName: speakerName,
        text: text,
        faction: faction,
      ));
    }

    return lines;
  }

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  late final List<DebateLine> _lines;
  int _currentLineIndex = 0;

  // 反応記録
  final List<DebateReactionRecord> _reactions = [];

  // 評価フェーズかどうか
  bool _showRatingPhase = false;

  // 評価マップ: candidateId → rating (1-5)
  final Map<String, int> _ratings = {};

  // 評価送信済みか
  bool _ratingsSubmitted = false;

  @override
  void initState() {
    super.initState();
    _lines = DebateScreen.generateDebateLines(widget.election.candidates);
    // 全候補者の評価を初期化（未評価=0）
    for (final c in widget.election.candidates) {
      _ratings[c.id] = 0;
    }
  }

  bool get _isFinished => _currentLineIndex >= _lines.length;

  /// 反応を記録して次の発言へ
  void _onReactionSelected(DebateReaction reaction) {
    if (_isFinished) return;

    setState(() {
      _reactions.add(DebateReactionRecord(
        speakerName: _lines[_currentLineIndex].speakerName,
        reaction: reaction,
        speechIndex: _currentLineIndex,
      ));

      _currentLineIndex++;

      // 全発言終了 → 評価フェーズへ
      if (_isFinished) {
        _showRatingPhase = true;
      }
    });
  }

  /// 評価を設定
  void _setRating(String candidateId, int rating) {
    setState(() {
      _ratings[candidateId] = rating;
    });
  }

  /// 評価を送信（SharedPreferencesに保存）
  void _submitRatings() {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final c in widget.election.candidates) {
      final rating = _ratings[c.id];
      if (rating != null && rating >= 1 && rating <= 5) {
        RatingService.saveRating(CandidateRating(
          candidateId: c.id,
          candidateName: c.name,
          rating: rating,
          ratedAt: now,
        ));
      }
    }
    setState(() {
      _ratingsSubmitted = true;
      _showRatingPhase = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: RetroPalette.bgDark,
        appBar: AppBar(
          title: const Text('討論会'),
        ),
        body: Column(
          children: [
            // ヘッダー
            SemanticHelper.interactive(
              testId: 'btn_debate_title',
              label: '候補者討論会',
              child: Container(
                key: AppKeys.debateTitle,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: RetroPalette.panelBg,
                child: const Text(
                  '候補者討論会',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RetroPalette.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 表示エリア
            Expanded(
              child: Center(
                child: _buildContent(),
              ),
            ),

            // 下部ボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBottomAction(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_ratingsSubmitted) {
      return _buildFinishedView();
    }
    if (_showRatingPhase) {
      return _buildRatingPanel();
    }
    if (_isFinished) {
      return const SizedBox.shrink(); // 到達しないはず
    }
    return _buildDebateView();
  }

  Widget _buildDebateView() {
    final line = _lines[_currentLineIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 候補者名
          SemanticHelper.interactive(
            testId: 'btn_debate_candidate_name',
            label: '発言者: ${line.speakerName}',
            child: Container(
              key: AppKeys.debateCandidateName,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: RetroPalette.panelBorder,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                line.speakerName,
                style: const TextStyle(
                  color: RetroPalette.bgDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (line.faction != null)
            Text(
              line.faction!,
              style: const TextStyle(
                color: RetroPalette.textAccent,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 16),

          // 発言内容（吹き出し）
          SemanticHelper.interactive(
            testId: 'btn_debate_speech_bubble',
            label: line.text,
            child: Container(
              key: AppKeys.debateSpeechBubble,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: RetroPalette.panelBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                line.text,
                style: const TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// プレイヤー反応選択パネル
  Widget _buildReactionButtons() {
    return Container(
      key: AppKeys.debateReactionPanel,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Text(
            'あなたの反応は？',
            style: TextStyle(
              color: RetroPalette.textAccent,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildReactionButton(
                key: AppKeys.debateReactionAgree,
                label: '同意する',
                icon: Icons.thumb_up,
                reaction: DebateReaction.agree,
              ),
              _buildReactionButton(
                key: AppKeys.debateReactionDisagree,
                label: '反対する',
                icon: Icons.thumb_down,
                reaction: DebateReaction.disagree,
              ),
              _buildReactionButton(
                key: AppKeys.debateReactionQuestion,
                label: '質問する',
                icon: Icons.help_outline,
                reaction: DebateReaction.question,
              ),
              _buildReactionButton(
                key: AppKeys.debateReactionSilent,
                label: '沈黙する',
                icon: Icons.remove_circle_outline,
                reaction: DebateReaction.silent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton({
    required Key key,
    required String label,
    required IconData icon,
    required DebateReaction reaction,
  }) {
    return SemanticHelper.interactive(
      testId: 'btn_debate_reaction_${reaction.name}',
      label: label,
      child: InkWell(
        key: key,
        onTap: () => _onReactionSelected(reaction),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: RetroPalette.panelBg,
            border: Border.all(color: RetroPalette.panelBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: RetroPalette.textAccent),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 候補者評価パネル
  Widget _buildRatingPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        key: AppKeys.debateRatingPanel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '候補者を評価してください',
              style: TextStyle(
                color: RetroPalette.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '各候補者の討論を1〜5の星で評価',
              style: TextStyle(
                color: RetroPalette.textAccent,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.election.candidates.map((c) =>
                _buildCandidateRating(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateRating(Candidate candidate) {
    final currentRating = _ratings[candidate.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            candidate.name,
            style: const TextStyle(
              color: RetroPalette.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            key: AppKeys.debateRatingStars(candidate.id),
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              final filled = starNumber <= currentRating;
              return GestureDetector(
                onTap: () => _setRating(candidate.id, starNumber),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? RetroPalette.gold : RetroPalette.textAccent,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: RetroPalette.success, size: 48),
        const SizedBox(height: 16),
        const Text(
          '討論終了',
          style: TextStyle(
            color: RetroPalette.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_reactions.length}件の反応と ${widget.election.candidates.length}名の評価を記録しました。',
          textAlign: TextAlign.center,
          style: const TextStyle(color: RetroPalette.textAccent, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    if (_ratingsSubmitted) {
      // 評価送信後 → 投票へ進むボタン
      return SizedBox(
        width: double.infinity,
        child: SemanticHelper.interactive(
          testId: 'btn_proceed_to_vote',
          label: '投票へ進む',
          child: ElevatedButton(
            key: AppKeys.debateToVoteButton,
            onPressed: widget.onProceedToVote,
            style: ElevatedButton.styleFrom(
              backgroundColor: RetroPalette.success,
            ),
            child: const Text('投票へ進む'),
          ),
        ),
      );
    }

    if (_showRatingPhase) {
      // 評価フェーズ → 評価を送信ボタン
      final allRated = widget.election.candidates.every(
        (c) => (_ratings[c.id] ?? 0) >= 1,
      );
      return SizedBox(
        width: double.infinity,
        child: SemanticHelper.interactive(
          testId: 'btn_submit_ratings',
          label: '評価を送信',
          child: ElevatedButton(
            key: AppKeys.debateRatingSubmit,
            onPressed: allRated ? _submitRatings : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: allRated
                  ? RetroPalette.success
                  : RetroPalette.panelBorder,
            ),
            child: Text(allRated ? '評価を送信' : '全候補者を評価してください'),
          ),
        ),
      );
    }

    // 討論中 → 反応ボタン
    return _buildReactionButtons();
  }
}
