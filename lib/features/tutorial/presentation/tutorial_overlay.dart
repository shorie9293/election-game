import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/tutorial/data/tutorial_service.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';

/// 吹き出しの表示位置
enum TutorialOverlayPosition {
  top,
  bottom,
  center,
}

/// チュートリアルの吹き出しオーバーレイWidget
///
/// 半透明黒背景の上に、吹き出し＋テキスト＋「次へ」「スキップ」ボタンを表示する。
class TutorialOverlay extends StatelessWidget {
  /// 表示するチュートリアルステップ
  final TutorialStep step;

  /// 子Widget（画面本体）
  final Widget child;

  /// 次へボタン押下時のコールバック
  final VoidCallback onNext;

  /// スキップボタン押下時のコールバック
  final VoidCallback onSkip;

  /// 吹き出しの表示位置
  final TutorialOverlayPosition position;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.child,
    required this.onNext,
    required this.onSkip,
    this.position = TutorialOverlayPosition.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: AppKeys.tutorialOverlay,
      children: [
        child,
        // 半透明オーバーレイ
        Positioned.fill(
          child: Container(color: Colors.black54),
        ),
        // 吹き出しとボタン
        _buildBubblePosition(),
      ],
    );
  }

  Widget _buildBubblePosition() {
    final bubble = _buildBubble();
    switch (position) {
      case TutorialOverlayPosition.top:
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
            child: bubble,
          ),
        );
      case TutorialOverlayPosition.center:
        return Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: bubble,
          ),
        );
      case TutorialOverlayPosition.bottom:
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
            child: bubble,
          ),
        );
    }
  }

  Widget _buildBubble() {
    final label = TutorialService.stepLabel(step);
    final description = TutorialService.stepDescription(step);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル行
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 説明文
          Semantics(
            key: AppKeys.tutorialText,
            label: description,
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ボタン行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SemanticHelper.interactive(
                testId: 'btn_tutorial_skip_button',
                label: 'チュートリアルをスキップ',
                child: TextButton(
                  key: AppKeys.tutorialSkipButton,
                  onPressed: onSkip,
                  child: const Text(
                    'スキップ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              SemanticHelper.interactive(
                testId: 'btn_tutorial_next_button',
                label: '次へ',
                child: ElevatedButton(
                  key: AppKeys.tutorialNextButton,
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('次へ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
