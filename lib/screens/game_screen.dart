import 'package:flutter/material.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/daily_event_service.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/domain/models/daily_event.dart';
import 'package:election_game/features/citizen/presentation/citizen_create_screen.dart';
import 'package:election_game/features/election/presentation/election_announcement_screen.dart';
import 'package:election_game/features/election/presentation/election_result_screen.dart';
import 'package:election_game/features/election/presentation/debate_screen.dart';
import 'package:election_game/features/election/presentation/vote_screen.dart';
import 'package:election_game/features/game/domain/game_phase.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/services/concern_evolution_service.dart';
import 'package:election_game/domain/models/concern_evolution.dart';
import 'package:election_game/features/tutorial/data/tutorial_service.dart';
import 'package:election_game/features/tutorial/domain/tutorial_state.dart';
import 'package:election_game/features/tutorial/presentation/tutorial_overlay.dart';
import 'package:election_game/features/town_square/presentation/town_square_screen.dart';
import 'package:election_game/domain/models/citizen_npc_relationship.dart';
import 'package:election_game/domain/models/opposition_citizen.dart';
import 'package:election_game/services/bgm_service.dart';
import 'package:election_game/services/audio_players_bgm_service.dart';

/// ゲーム全体の状態を管理し、画面遷移を制御するStatefulWidget
///
/// GamePhaseに応じて画面を切り替え、各画面のコールバックから
/// GameStateを更新して次のフェーズへ遷移する。
/// スケール進行（村→町→市）に応じた段階進行をサポート。
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GamePhase _currentPhase = GamePhase.citizenCreate;
  GameState _gameState = GameState(
    citizen: Citizen.initial(Job.farmer),
    society: SocietyState.initial(),
    remainingTurns: 0,
  );
  Map<String, int> _lifeParamChanges = {};
  String? _votedCandidateId;
  bool _abstained = false;
  DailyEvent? _lastDailyEvent;

  TutorialState _tutorialState = TutorialState.initial();
  bool _tutorialLoaded = false;
  bool _participatedInDebate = false;

  /// BGM再生サービス。本番環境では AudioPlayersBgmService 等に差し替え可能。
  final BgmService _bgmService = AudioPlayersBgmService();

  @override
  void initState() {
    super.initState();
    _initTutorial();
    _playBgmForScale();
  }

  /// BGM切替 — ElectionScale に応じたトラックを再生する。
  void _playBgmForScale() {
    final track = BgmTrack.fromScale(_gameState.scale);
    _bgmService.play(track);
  }

  @override
  void dispose() {
    _bgmService.dispose();
    super.dispose();
  }

  Future<void> _initTutorial() async {
    final isFirst = await TutorialService.isFirstLaunch();
    setState(() {
      _tutorialState = TutorialState(
        isActive: isFirst,
        hasCompleted: !isFirst,
      );
      _tutorialLoaded = true;
    });
  }

  /// キャラクター作成完了 → homeへ
  void _onCitizenCreated(Citizen citizen) {
    // 初期関心事を ConcernEvolution として記録
    final initialEvolutions = citizen.concerns
        .map((c) => ConcernEvolution.initial(c))
        .toList();
    setState(() {
      _gameState = _gameState.copyWith(
        citizen: citizen,
        concernEvolutions: initialEvolutions,
      );
      _currentPhase = GamePhase.home;
    });
  }

  /// 行動選択（ターン進行＋アクション別イベント発生）
  void _onActionSelected(DailyAction action) {
    // NPCと話す場合は町広場に移動
    if (action == DailyAction.talkToNpc) {
      _showTownSquare();
      return;
    }

    final event = DailyEventService.generateForAction(
      action,
      _gameState.citizen,
      _gameState.society,
    );

    // 非選択肢イベントの効果を即時反映
    Citizen updatedCitizen = _gameState.citizen;
    if (event != null && event.choices == null && event.effects != null) {
      final newLifeParams =
          Map<String, int>.from(_gameState.citizen.lifeParams);
      for (final entry in event.effects!.entries) {
        final key = entry.key == 'happiness'
            ? entry.key
            : entry.key;
        if (key == 'happiness') {
          // happinessはSocietyStateのものなのでここでは飛ばす
          continue;
        }
        newLifeParams[key] =
            (newLifeParams[key] ?? 50) + entry.value;
      }
      updatedCitizen = _gameState.citizen.copyWith(lifeParams: newLifeParams);
    }

    setState(() {
      _lastDailyEvent = event;
      _gameState = _gameState.copyWith(
        citizen: updatedCitizen,
        remainingTurns: _gameState.remainingTurns - 1,
      );
    });
  }

  /// 選択肢イベントの選択結果を反映
  void _onChoiceSelected(DailyEvent event, EventChoice choice) {
    final newLifeParams =
        Map<String, int>.from(_gameState.citizen.lifeParams);
    if (choice.effects != null) {
      for (final entry in choice.effects!.entries) {
        final key = entry.key;
        if (key == 'happiness') {
          // happinessはSocietyState側
          continue;
        }
        newLifeParams[key] =
            (newLifeParams[key] ?? 50) + entry.value;
      }
    }
    // event自身のeffectsもあれば適用（選択肢に加えて）
    if (event.effects != null) {
      for (final entry in event.effects!.entries) {
        final key = entry.key;
        if (key == 'happiness') continue;
        newLifeParams[key] =
            (newLifeParams[key] ?? 50) + entry.value;
      }
    }

    setState(() {
      _gameState = _gameState.copyWith(
        citizen: _gameState.citizen.copyWith(lifeParams: newLifeParams),
      );
      _lastDailyEvent = null;
    });
  }

  /// 選挙開始 → announcementへ
  void _onStartElection() {
    final candidates = ElectionService.determineCandidates(_gameState.society);
    final election = Election(
      id: 'election_${DateTime.now().millisecondsSinceEpoch}',
      title: '${_gameState.scale.displayName} ${_gameState.scale.title}',
      scale: _gameState.scale,
      candidates: candidates,
    );
    setState(() {
      _gameState = _gameState.copyWith(currentElection: election);
      _currentPhase = GamePhase.electionAnnouncement;
    });
  }

  /// 町広場画面を表示
  void _showTownSquare() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TownSquareScreen(
          npcs: OppositionCitizen.samples(),
          societyMood: _gameState.society.mood,
          npcRelationships: _gameState.npcRelationships,
          onNpcInteract: _onNpcInteract,
        ),
      ),
    ).then((_) {
      // 町広場から戻ったらターンを消費
      setState(() {
        _gameState = _gameState.copyWith(
          remainingTurns: _gameState.remainingTurns - 1,
        );
      });
    });
  }

  /// NPCとの対話を記録
  void _onNpcInteract(String npcId) {
    setState(() {
      final existing = _gameState.npcRelationships[npcId];
      final updated = existing != null
          ? existing.recordInteraction()
          : CitizenNpcRelationship.initial(npcId).recordInteraction();
      final newRelationships =
          Map<String, CitizenNpcRelationship>.from(_gameState.npcRelationships);
      newRelationships[npcId] = updated;
      _gameState = _gameState.copyWith(npcRelationships: newRelationships);
    });
  }

  /// 討論会画面へ進む
  void _onProceedToDebate() {
    _participatedInDebate = true;
    setState(() => _currentPhase = GamePhase.debate);
  }

  /// 投票画面へ進む（討論会から）
  void _onProceedToVoteFromDebate() {
    setState(() => _currentPhase = GamePhase.vote);
  }

  /// 投票実行 → resultへ
  void _onVoteCast(String candidateId) {
    _votedCandidateId = candidateId;
    _abstained = false;
    final election =
        _gameState.currentElection!.copyWith(voterId: candidateId);
    final result = ElectionService.computeElectionResult(election);

    final newLifeParams = ElectionService.applyElectionToLife(
      _gameState.citizen.lifeParams,
      result,
    );
    _lifeParamChanges =
        _computeLifeParamDiff(_gameState.citizen.lifeParams, newLifeParams);

    setState(() {
      _gameState = _gameState.copyWith(currentElection: result);
      _currentPhase = GamePhase.result;
    });
  }

  /// 棄権 → resultへ
  void _onAbstain() {
    _votedCandidateId = null;
    _abstained = true;
    final result =
        ElectionService.computeElectionResult(_gameState.currentElection!);

    final newLifeParams = ElectionService.applyElectionToLife(
      _gameState.citizen.lifeParams,
      result,
    );
    _lifeParamChanges =
        _computeLifeParamDiff(_gameState.citizen.lifeParams, newLifeParams);

    setState(() {
      _gameState = _gameState.copyWith(currentElection: result);
      _currentPhase = GamePhase.result;
    });
  }

  /// 街に戻る（選挙結果を反映） → home または ending
  /// スケール進行（村→町→市）を管理
  void _onContinue() {
    final result = _gameState.currentElection!;

    // ライフパラメータに当選者の政策を適用
    final newLifeParams = ElectionService.applyElectionToLife(
      _gameState.citizen.lifeParams,
      result,
    );
    final updatedCitizen =
        _gameState.citizen.copyWith(lifeParams: newLifeParams);

    // 社会ムード変化を計算
    final newMood = ElectionService.computeMoodChange(
      _gameState.society,
      result,
    );

    // 幸福度変化を計算
    final newHappiness = _votedCandidateId != null
        ? ElectionService.computeHappinessChange(
            _gameState.society,
            result,
            _votedCandidateId!,
          )
        : _gameState.society.happiness;

    final updatedSociety = _gameState.society.copyWith(
      mood: newMood,
      happiness: newHappiness,
      currentLeaderId: result.winnerId,
      electionCount: _gameState.society.electionCount + 1,
    );

    // 選挙カウントを増やし、スケール進行を判定
    final newElectionCount = _gameState.electionCount + 1;
    final currentScale = _gameState.scale;

    // 現在のスケールで必要な選挙回数に達したか
    final shouldAdvanceScale =
        newElectionCount % currentScale.electionsNeeded == 0;

    // 次のスケールがあるか（cityが最終）
    final nextScale = currentScale.advanceTo;
    final hasNextScale = nextScale != null;

    // エンディング判定: cityの3回目の選挙後
    // currentScale == city かつ shouldAdvanceScale で終了
    final isFinalEnding = currentScale == ElectionScale.city && shouldAdvanceScale;

    // 懸念進化: 選挙結果と討論参加に基づき、新たな関心事を獲得
    final newEvolutions = ConcernEvolutionService.computeConcernEvolutions(
      citizen: _gameState.citizen,
      lastElectionResult: result,
      participatedInDebate: _participatedInDebate,
      electionCount: newElectionCount,
      currentEvolutions: _gameState.concernEvolutions,
    );
    final updatedEvolutions = [
      ..._gameState.concernEvolutions,
      ...newEvolutions,
    ];

    // 新しい関心事を市民モデルに反映
    Citizen citizenWithNewConcerns = updatedCitizen;
    if (newEvolutions.isNotEmpty) {
      final newConcerns = newEvolutions.map((e) => e.concern).toList();
      final allConcerns = [
        ...updatedCitizen.concerns,
        ...newConcerns.where((c) => !updatedCitizen.concerns.contains(c)),
      ];
      citizenWithNewConcerns = updatedCitizen.copyWith(concerns: allConcerns);
    }

    setState(() {
      _gameState = GameState(
        citizen: citizenWithNewConcerns,
        society: updatedSociety,
        remainingTurns: isFinalEnding
            ? 0
            : ElectionService.computeNextElectionTurns(),
        electionCount: newElectionCount,
        scale: shouldAdvanceScale && hasNextScale
            ? nextScale
            : currentScale,
        concernEvolutions: updatedEvolutions,
        npcRelationships: _gameState.npcRelationships,
      );
      _currentPhase = isFinalEnding ? GamePhase.ending : GamePhase.home;
      _lifeParamChanges = {};
      _votedCandidateId = null;
      _abstained = false;
      _participatedInDebate = false;
    });

    if (shouldAdvanceScale && hasNextScale) {
      _playBgmForScale();
    }
  }

  /// ライフパラメータ変化量を計算
  Map<String, int> _computeLifeParamDiff(
    Map<String, int> oldParams,
    Map<String, int> newParams,
  ) {
    final diff = <String, int>{};
    for (final entry in newParams.entries) {
      final oldValue = oldParams[entry.key] ?? 0;
      final change = entry.value - oldValue;
      if (change != 0) {
        diff[entry.key] = change;
      }
    }
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    // 内部画面がそれぞれScaffoldを持つので二重Scaffoldを避ける
    var body = _buildPhaseWidget();
    if (_tutorialState.isActive && _tutorialLoaded) {
      final step = TutorialService.stepForPhase(_currentPhase);
      if (step != null) {
        body = TutorialOverlay(
          step: step,
          onNext: () => setState(() {}),
          onSkip: () {
            TutorialService.markCompleted();
            setState(() => _tutorialState = _tutorialState.copyWith(
              isActive: false,
              isSkipped: true,
            ));
          },
          child: body,
        );
      }
    }
    return body;
  }

  Widget _buildPhaseWidget() {
    switch (_currentPhase) {
      case GamePhase.citizenCreate:
        return CitizenCreateScreen(
          onCitizenCreated: _onCitizenCreated,
        );
      case GamePhase.home:
        return HomeScreen(
          citizen: _gameState.citizen,
          societyState: _gameState.society,
          remainingTurns: _gameState.remainingTurns,
          dailyEvent: _lastDailyEvent,
          concernEvolutions: _gameState.concernEvolutions,
          onStartElection: _onStartElection,
          onActionSelected: _onActionSelected,
          onChoiceSelected: _onChoiceSelected,
        );
      case GamePhase.electionAnnouncement:
        return ElectionAnnouncementScreen(
          election: _gameState.currentElection!,
          onProceed: _onProceedToDebate,
        );
      case GamePhase.debate:
        return DebateScreen(
          election: _gameState.currentElection!,
          onProceedToVote: _onProceedToVoteFromDebate,
        );
      case GamePhase.vote:
        return VoteScreen(
          election: _gameState.currentElection!,
          onVoteCast: _onVoteCast,
          onAbstain: _onAbstain,
        );
      case GamePhase.result:
        return ElectionResultScreen(
          result: _gameState.currentElection!,
          lifeParamChanges: _lifeParamChanges,
          votedCandidateId: _votedCandidateId,
          abstained: _abstained,
          onContinue: _onContinue,
        );
      case GamePhase.ending:
        return _EndingScreen(
          citizen: _gameState.citizen,
          societyState: _gameState.society,
          scale: _gameState.scale,
          concernEvolutions: _gameState.concernEvolutions,
        );
    }
  }
}

/// エンディング画面
class _EndingScreen extends StatelessWidget {
  final Citizen citizen;
  final SocietyState societyState;
  final ElectionScale scale;
  final List<ConcernEvolution> concernEvolutions;

  const _EndingScreen({
    required this.citizen,
    required this.societyState,
    required this.scale,
    this.concernEvolutions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final moodLabel = societyState.moodLabel;
    final happiness = societyState.happiness.toInt();
    final placeName = scale.displayName;

    String endingMessage;
    if (societyState.mood < 0.3) {
      endingMessage = '$placeNameは健全な民主主義を取り戻し、\\n市民一人ひとりの声が届く$placeNameになりました。';
    } else if (societyState.mood > 0.7) {
      endingMessage = '$placeNameは強い指導者のもと、\\n秩序ある発展を遂げました。\\nしかし、市民の声は遠くなってしまいました。';
    } else {
      endingMessage = '$placeNameはバランスの取れた社会へと\\n歩みを進めています。\\nあなたの一票が$placeNameを変えました。';
    }

    String scaleMessage;
    switch (scale) {
      case ElectionScale.city:
        scaleMessage = 'あなたは天照村から天照市までの\\n9回の選挙を経験しました。\\nあなたの選択が街の未来を形作りました。';
      case ElectionScale.town:
        scaleMessage = '6回の選挙を終え、天照町として\\n歩みを続けています。';
      case ElectionScale.village:
        scaleMessage = '3回の選挙を終え、天照村として\\n新たな一歩を踏み出しました。';
    }

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 64, color: RetroPalette.gold),
              const SizedBox(height: 24),
              const Text(
                'エンディング',
                style: TextStyle(
                  color: RetroPalette.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '〜 ${citizen.name}の物語 〜',
                style: const TextStyle(
                  color: RetroPalette.textAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.panelBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      endingMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 16,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '社会の空気: $moodLabel  |  幸福度: $happiness',
                      style: const TextStyle(
                        color: RetroPalette.textAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scaleMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 獲得した関心事の表示
              if (concernEvolutions.any((e) => e.isAcquired))
                _EndingConcernGrowth(
                  key: AppKeys.endingConcernGrowth,
                  evolutions: concernEvolutions,
                ),
              if (concernEvolutions.any((e) => e.isAcquired))
                const SizedBox(height: 24),

              const Text(
                '〜 Thank you for playing 〜',
                style: TextStyle(
                  color: RetroPalette.textAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// エンディング用の政治的成長表示
class _EndingConcernGrowth extends StatelessWidget {
  final List<ConcernEvolution> evolutions;

  const _EndingConcernGrowth({super.key, required this.evolutions});

  @override
  Widget build(BuildContext context) {
    final acquired = evolutions.where((e) => e.isAcquired).toList();
    if (acquired.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.gold.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: RetroPalette.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'この旅で広がった関心',
                style: TextStyle(
                  color: RetroPalette.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...acquired.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.concern.label,
                  style: const TextStyle(
                    color: RetroPalette.textNormal,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.reason,
                    style: const TextStyle(
                      color: RetroPalette.textAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 10),
          Text(
            'あなたは ${acquired.length} つの新しい関心事を得ました。\nあなたの一票一票が視野を広げました。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RetroPalette.textAccent,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
