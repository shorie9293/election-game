import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';
import 'package:election_game/features/game/domain/game_phase.dart';

/// チュートリアル進行を管理するサービス
class TutorialService {
  TutorialService._();

  static const _completedKey = 'election_game_tutorial_completed';

  /// 初回起動かどうかを確認する
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_completedKey) ?? false;
    return !completed;
  }

  /// チュートリアル完了を保存する
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  /// GamePhase に対応する TutorialStep を返す
  static TutorialStep? stepForPhase(GamePhase phase) {
    switch (phase) {
      case GamePhase.citizenCreate:
        return TutorialStep.citizenCreate;
      case GamePhase.home:
        return TutorialStep.home;
      case GamePhase.electionAnnouncement:
        return TutorialStep.home;
      case GamePhase.debate:
        return TutorialStep.debate;
      case GamePhase.vote:
        return TutorialStep.vote;
      case GamePhase.result:
        return TutorialStep.postElection;
      case GamePhase.ending:
        return null;
    }
  }

  /// チュートリアルステップの日本語ラベルを返す
  static String stepLabel(TutorialStep step) => step.label;

  /// チュートリアルステップの吹き出し本文を返す
  static String stepDescription(TutorialStep step) => step.description;
}
