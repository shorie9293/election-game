import 'package:equatable/equatable.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';

/// チュートリアルの状態を管理するモデル
class TutorialState extends Equatable {
  /// チュートリアル中か
  final bool isActive;
  /// 完了済み（2回目以降スキップ用）
  final bool hasCompleted;
  /// 現在のチュートリアルステップ
  final TutorialStep? currentStep;
  /// スキップされたか
  final bool isSkipped;

  const TutorialState({
    this.isActive = false,
    this.hasCompleted = false,
    this.currentStep,
    this.isSkipped = false,
  });

  /// デフォルト状態（非アクティブ）
  factory TutorialState.initial() => const TutorialState();

  /// 一部フィールドを変更した新しいインスタンスを生成
  TutorialState copyWith({
    bool? isActive,
    bool? hasCompleted,
    TutorialStep? currentStep,
    bool? isSkipped,
    bool clearStep = false,
  }) {
    return TutorialState(
      isActive: isActive ?? this.isActive,
      hasCompleted: hasCompleted ?? this.hasCompleted,
      currentStep: clearStep ? null : (currentStep ?? this.currentStep),
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }

  /// JSON シリアライズ
  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'has_completed': hasCompleted,
      'current_step': currentStep?.name,
      'is_skipped': isSkipped,
    };
  }

  /// JSON デシリアライズ
  factory TutorialState.fromJson(Map<String, dynamic> json) {
    return TutorialState(
      isActive: json['is_active'] as bool? ?? false,
      hasCompleted: json['has_completed'] as bool? ?? false,
      currentStep: (json['current_step'] as String?) != null
          ? TutorialStep.values.firstWhere(
              (e) => e.name == json['current_step'],
              orElse: () => TutorialStep.citizenCreate,
            )
          : null,
      isSkipped: json['is_skipped'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [isActive, hasCompleted, currentStep, isSkipped];
}
