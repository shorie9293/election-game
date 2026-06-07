import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/daily_event.dart';
import 'package:election_game/domain/models/concern_evolution.dart';

/// メイン画面（生活パラメータ＋行動選択＋デイリーイベント）
class HomeScreen extends StatefulWidget {
  final Citizen citizen;
  final SocietyState societyState;
  final int remainingTurns;
  final DailyEvent? dailyEvent;
  final List<ConcernEvolution> concernEvolutions;
  final VoidCallback? onStartElection;
  final void Function(DailyAction action)? onActionSelected;
  final void Function(DailyEvent event, EventChoice choice)? onChoiceSelected;

  const HomeScreen({
    super.key,
    required this.citizen,
    required this.societyState,
    required this.remainingTurns,
    this.dailyEvent,
    this.concernEvolutions = const [],
    this.onStartElection,
    this.onActionSelected,
    this.onChoiceSelected,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DailyEvent? _currentEvent;
  bool _isFirstBuild = true;

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dailyEvent != oldWidget.dailyEvent) {
      _currentEvent = widget.dailyEvent;
      if (_currentEvent?.choices != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showChoiceDialog(_currentEvent!);
        });
      }
    }
  }

  void _checkForChoiceDialog() {
    if (_currentEvent == null && widget.dailyEvent?.choices != null) {
      _currentEvent = widget.dailyEvent;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showChoiceDialog(_currentEvent!);
      });
    }
  }

  void _showChoiceDialog(DailyEvent event) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          key: AppKeys.homeChoiceDialog,
          backgroundColor: RetroPalette.panelBg,
          title: Row(
            children: [
              Text(event.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(color: RetroPalette.gold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            event.description,
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          actions: event.choices!.map((choice) {
            return TextButton(
              key: Key('${AppKeys.homeChoiceOption}_${choice.label}'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onChoiceSelected?.call(event, choice);
              },
              child: Text(
                choice.label,
                style: const TextStyle(color: RetroPalette.textAccent),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      _checkForChoiceDialog();
    }
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: Text(
          '天照町 — ${widget.citizen.name}',
          key: AppKeys.homeTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 市民情報
            SemanticHelper.interactive(
              testId: 'btn_home_citizen_info',
              label: '市民情報',
              child: _CitizenInfoCard(
                key: AppKeys.homeCitizenInfo,
                citizen: widget.citizen,
              ),
            ),
            const SizedBox(height: 16),

            // 政治的成長（獲得関心事が初期より増えた場合のみ表示）
            if (widget.concernEvolutions.any((e) => e.isAcquired))
              ...[
                SemanticHelper.interactive(
                  testId: 'btn_home_concern_growth',
                  label: '政治的成長',
                  child: _ConcernGrowthCard(
                    key: AppKeys.homeConcernGrowth,
                    evolutions: widget.concernEvolutions,
                  ),
                ),
                const SizedBox(height: 16),
              ],

            // 社会ムード
            SemanticHelper.interactive(
              testId: 'btn_home_society_mood',
              label: '社会ムード',
              child: _MoodCard(
                key: AppKeys.homeSocietyMood,
                societyState: widget.societyState,
              ),
            ),
            const SizedBox(height: 16),

            // デイリーイベント
            if (widget.dailyEvent != null && widget.dailyEvent!.choices == null) ...[
              SemanticHelper.interactive(
                testId: 'btn_home_daily_event',
                label: '今日の出来事',
                child: _DailyEventCard(
                  key: AppKeys.homeDailyEvent,
                  event: widget.dailyEvent!,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 生活パラメータ
            SemanticHelper.interactive(
              testId: 'btn_home_life_params',
              label: '生活パラメータ',
              child: _LifeParamsCard(
                key: AppKeys.homeLifeParams,
                citizen: widget.citizen,
              ),
            ),
            const SizedBox(height: 16),

            // カウントダウン
            SemanticHelper.interactive(
              testId: 'btn_home_countdown',
              label: '次回選挙までのカウントダウン',
              child: _CountdownCard(
                key: AppKeys.homeCountdown,
                remainingTurns: widget.remainingTurns,
              ),
            ),
            const SizedBox(height: 24),

            // 行動選択ボタン（remainingTurns > 0 のとき表示）
            if (widget.remainingTurns > 0) ...[
              const Text(
                '今日は何をしよう？',
                style: TextStyle(color: RetroPalette.textAccent, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _ActionButton(
                key: AppKeys.homeActionTalkNpc,
                icon: Icons.people,
                label: 'NPCと話す',
                description: '町の人と会話して社会の空気を感じる',
                color: RetroPalette.textAccent,
                onPressed: () =>
                    widget.onActionSelected?.call(DailyAction.talkToNpc),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                key: AppKeys.homeActionGatherInfo,
                icon: Icons.search,
                label: '情報収集',
                description: '新聞や公約を調べて判断材料を集める',
                color: RetroPalette.gold,
                onPressed: () =>
                    widget.onActionSelected?.call(DailyAction.gatherInfo),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                key: AppKeys.homeActionRest,
                icon: Icons.self_improvement,
                label: '休む（残り${widget.remainingTurns}日）',
                description: 'ゆっくり過ごして生活パラメータを回復',
                color: RetroPalette.success,
                onPressed: () =>
                    widget.onActionSelected?.call(DailyAction.rest),
              ),
              const SizedBox(height: 12),
            ],

            // 選挙に行くボタン
            if (widget.remainingTurns <= 0)
              SemanticHelper.interactive(
                testId: 'btn_start_election',
                label: '選挙に行く',
                child: ElevatedButton.icon(
                  key: AppKeys.homeElectionButton,
                  onPressed: widget.onStartElection,
                  icon: const Icon(Icons.how_to_vote),
                  label: const Text('選挙に行く'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 行動選択ボタン
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          color: RetroPalette.textNormal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CitizenInfoCard extends StatelessWidget {
  final Citizen citizen;
  const _CitizenInfoCard({super.key, required this.citizen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: RetroPalette.panelBorder.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: RetroPalette.textAccent),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                citizen.name,
                style: const TextStyle(
                  color: RetroPalette.gold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '職業: ${citizen.job.label}',
                style: const TextStyle(color: RetroPalette.textNormal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final SocietyState societyState;
  const _MoodCard({super.key, required this.societyState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: societyState.moodColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '社会の空気',
            style: TextStyle(color: RetroPalette.textAccent, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: societyState.moodColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                societyState.moodLabel,
                style: TextStyle(
                  color: societyState.moodColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '幸福度: ${societyState.happiness.toInt()}',
                style: const TextStyle(color: RetroPalette.textNormal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LifeParamsCard extends StatelessWidget {
  final Citizen citizen;
  const _LifeParamsCard({super.key, required this.citizen});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            '生活パラメータ',
            style: TextStyle(color: RetroPalette.textAccent, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...citizen.lifeParams.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      LifeParamKeys.label(e.key),
                      style: const TextStyle(color: RetroPalette.textNormal),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / 100,
                        backgroundColor: RetroPalette.bgDark,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _paramColor(e.value),
                        ),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(color: RetroPalette.textNormal),
                      textAlign: TextAlign.right,
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

  Color _paramColor(int value) {
    if (value >= 70) return RetroPalette.success;
    if (value >= 40) return RetroPalette.warning;
    return RetroPalette.danger;
  }
}

class _CountdownCard extends StatelessWidget {
  final int remainingTurns;
  const _CountdownCard({super.key, required this.remainingTurns});

  @override
  Widget build(BuildContext context) {
    final isElectionTime = remainingTurns <= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(
          color: isElectionTime ? RetroPalette.gold : RetroPalette.panelBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            '次回選挙まで',
            style: TextStyle(color: RetroPalette.textAccent, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
              isElectionTime ? '今すぐ!' : '$remainingTurns',
            style: TextStyle(
              color:
                  isElectionTime ? RetroPalette.gold : RetroPalette.textNormal,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isElectionTime)
            const Text(
              '投票に行きましょう！',
              style: TextStyle(color: RetroPalette.gold),
            ),
        ],
      ),
    );
  }
}

class _DailyEventCard extends StatelessWidget {
  final DailyEvent event;
  const _DailyEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.gold.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(event.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日の出来事${event.actionType != null ? "（${_actionLabel(event.actionType!)}）" : ""}',
                  style: const TextStyle(
                    color: RetroPalette.textAccent,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: RetroPalette.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
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
    );
  }

  static String _actionLabel(DailyAction action) {
    switch (action) {
      case DailyAction.talkToNpc:
        return '会話';
      case DailyAction.gatherInfo:
        return '情報収集';
      case DailyAction.rest:
        return '休息';
    }
  }
}

/// 政治的成長表示カード
///
/// キャラメイク時より獲得した関心事を表示する。
/// 獲得関心事がなければ何も表示しない。
class _ConcernGrowthCard extends StatelessWidget {
  final List<ConcernEvolution> evolutions;

  const _ConcernGrowthCard({super.key, required this.evolutions});

  @override
  Widget build(BuildContext context) {
    final acquired = evolutions.where((e) => e.isAcquired).toList();
    if (acquired.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: RetroPalette.gold, size: 18),
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
                '+${acquired.length}',
                style: const TextStyle(
                  color: RetroPalette.textAccent,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...acquired.map((e) => Padding(
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
    );
  }
}
