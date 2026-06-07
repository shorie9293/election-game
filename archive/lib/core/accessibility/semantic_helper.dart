import 'package:flutter/material.dart';

/// アクセシビリティ支援。
/// 全操作可能要素にSemantics情報を付与する。
class SemanticHelper {
  const SemanticHelper._();

  /// インタラクティブ要素（ボタン・選択肢等）
  static Widget interactive({
    required Key key,
    required String label,
    bool button = false,
    required Widget child,
  }) =>
      Semantics(
        key: key,
        label: label,
        button: button,
        child: child,
      );

  /// タイトル等の読み上げ用ヘッダー
  static Widget header({
    required Key key,
    required String label,
    required Widget child,
  }) =>
      Semantics(
        key: key,
        header: true,
        label: label,
        child: child,
      );
}
