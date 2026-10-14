import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/quiz_result.dart';
import 'package:election_game/domain/repositories/quiz_repository.dart';
import 'package:election_game/features/achievements/domain/achievement_badge.dart';
import 'package:election_game/features/achievements/domain/achievement_badge_service.dart';

/// プレイヤー実績バッジのコレクション画面。
///
/// 選挙の歩み（実施回数・投票的中・到達スケール・活動日数）とクイズの
/// 自己ベストから算出した実績バッジを、獲得済み／未獲得の別に一覧表示する。
/// 未獲得のバッジも達成条件と進捗を提示し、次の目標を示す。
/// 試練では [quizBestOverride] を注入して IO を回避できる。
class AchievementBadgeScreen extends StatefulWidget {
  /// 実施した選挙の回数
  final int electionCount;

  /// 現在の到達スケール
  final ElectionScale scale;

  /// 完了済み選挙の履歴
  final List<Election> pastElections;

  /// クイズ自己ベストの読込先（試練では差し替え可能）
  final QuizRepository quizRepository;

  /// 試練用：非 null なら [quizRepository] を使わずこの値で判定する
  final QuizBestScore? quizBestOverride;

  const AchievementBadgeScreen({
    super.key,
    this.electionCount = 0,
    this.scale = ElectionScale.village,
    this.pastElections = const [],
    this.quizRepository = const QuizRepository(),
    this.quizBestOverride,
  });

  @override
  State<AchievementBadgeScreen> createState() => _AchievementBadgeScreenState();
}

class _AchievementBadgeScreenState extends State<AchievementBadgeScreen> {
  QuizBestScore? _best;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final override = widget.quizBestOverride;
    if (override != null) {
      _best = override;
      _loading = false;
    } else {
      _loadBest();
    }
  }

  Future<void> _loadBest() async {
    try {
      final loaded = await widget.quizRepository.loadBest();
      if (!mounted) return;
      setState(() {
        _best = loaded;
        _loading = false;
      });
    } catch (_) {
      // クイズ記録の読込失敗でバッジ画面自体を止めない
      if (!mounted) return;
      setState(() {
        _best = null;
        _loading = false;
      });
    }
  }

  AchievementSignals get _signals => AchievementSignals(
        electionCount: widget.electionCount,
        scale: widget.scale,
        pastElections: widget.pastElections,
        quizBest: _best,
      );

  @override
  Widget build(BuildContext context) {
    final collection = AchievementBadgeService.collect(_signals);
    return Scaffold(
      key: AppKeys.achievementScreen,
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('実績バッジ'),
        backgroundColor: RetroPalette.panelBg,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(collection),
      ),
    );
  }

  Widget _buildBody(AchievementBadgeCollection collection) {
    return SingleChildScrollView(
      key: AppKeys.achievementList,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummary(collection),
          const SizedBox(height: 16),
          for (final tier in BadgeTier.values) ...[
            _buildTierSection(collection, tier),
            const SizedBox(height: 16),
          ],
          const Text(
            'バッジは選挙の歩みとクイズの学びに応じて解放されます。',
            style: TextStyle(color: RetroPalette.textAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(AchievementBadgeCollection collection) {
    return Container(
      key: AppKeys.achievementSummary,
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
            '実績の歩み',
            style: TextStyle(
              color: RetroPalette.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            collection.summaryLabel,
            style: const TextStyle(
              color: RetroPalette.textNormal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: collection.completionRatio,
            backgroundColor: RetroPalette.panelBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(RetroPalette.gold),
          ),
          const SizedBox(height: 8),
          Text(
            '達成率 ${(collection.completionRatio * 100).round()}%',
            style: const TextStyle(color: RetroPalette.textAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTierSection(
    AchievementBadgeCollection collection,
    BadgeTier tier,
  ) {
    final items = collection.byTier(tier);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final earned = items.where((p) => p.isEarned).length;
    return Column(
      key: AppKeys.achievementTierSection(tier.name),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(tier.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              tier.label,
              style: const TextStyle(
                color: RetroPalette.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$earned / ${items.length}',
              style: const TextStyle(
                color: RetroPalette.textAccent,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final p in items) _buildBadgeRow(p),
      ],
    );
  }

  Widget _buildBadgeRow(AchievementBadgeProgress p) {
    final earned = p.isEarned;
    return Container(
      key: AppKeys.achievementBadgeRow(p.definition.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(
          color: earned ? RetroPalette.gold : RetroPalette.panelBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            earned ? Icons.emoji_events : Icons.lock_outline,
            color: earned ? RetroPalette.gold : RetroPalette.textAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.definition.name,
                  style: TextStyle(
                    color: earned
                        ? RetroPalette.textNormal
                        : RetroPalette.textAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.definition.description,
                  style: const TextStyle(
                    color: RetroPalette.textAccent,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  key: AppKeys.achievementBadgeProgress(p.definition.id),
                  value: p.ratio,
                  backgroundColor: RetroPalette.panelBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    earned ? RetroPalette.gold : RetroPalette.textAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.progressLabel,
                  style: const TextStyle(
                    color: RetroPalette.textAccent,
                    fontSize: 11,
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
