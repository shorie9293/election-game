import 'package:flutter/foundation.dart';

/// ヘルプ画面に表示する1項目（読み返し用の章）。
///
/// 文言は既存チュートリアル（[TutorialStep] の label / description）を
/// 正とし、ここでは保持するだけ。二重管理しない。
@immutable
class HelpTopic {
  const HelpTopic({
    required this.id,
    required this.title,
    required this.body,
    this.relatedScreenKey,
  });

  /// 一意な識別子（TutorialStep.name を用いる）。
  final String id;

  /// 章タイトル。
  final String title;

  /// 本文（読み返し用の説明）。
  final String body;

  /// 関連する画面の試験用Key（任意）。
  final Key? relatedScreenKey;
}
