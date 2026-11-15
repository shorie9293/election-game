// 空状態の共通部品 — 文言（純粋データ）と描画（ウィジェット）を分離する。
//
// 空状態に「次の一手」を必ず差し出せるようにするための土台。
// 文言は呼出側が渡す（この部品は文章を持たない）。
//
// 命名規則・Semantics は コード適応神書 原則③ に従う。

import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart';

/// 空状態の文言と次の一手を表す不変データ。
///
/// 不変条件に違反すれば**生成時に必ず失敗する**（assert ではなく [ArgumentError]）。
/// リリースビルドでも不正な空状態を作らせないため。
class EmptyStateSpec {
  /// 見出し（必須・空文字不可）。
  final String title;

  /// 補足説明（任意）。
  final String? description;

  /// 操作ボタンのラベル。[onAction] と同時に指定するか、同時に省略する。
  final String? actionLabel;

  /// 操作ボタンの処理。[actionLabel] と同時に指定するか、同時に省略する。
  final VoidCallback? onAction;

  /// 不変条件を検証して生成する（意図的に非 const のコンストラクタ）。
  EmptyStateSpec({
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  }) {
    final label = actionLabel;
    final desc = description;
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', '空状態の見出しは空文字にできません');
    }
    if (desc != null && desc.trim().isEmpty) {
      throw ArgumentError.value(
        desc,
        'description',
        '空状態の説明は空文字にできません（不要なら null）',
      );
    }
    if ((label == null) != (onAction == null)) {
      throw ArgumentError(
        'actionLabel と onAction は同時に指定するか、同時に省略してください',
      );
    }
    if (label != null && label.trim().isEmpty) {
      throw ArgumentError.value(
        label,
        'actionLabel',
        '操作ラベルは空文字にできません',
      );
    }
  }

  /// 操作ボタンを差し出せるか。
  bool get hasAction => actionLabel != null && onAction != null;
}

/// 空状態の描画。[EmptyStateSpec] の文言を、アイコン・見出し・説明・任意ボタンで表す。
///
/// [key] は必須（画面ごとに空状態を一意に指せるようにする）。
/// [spec] に操作が無ければボタンは描画しない。
class EmptyStateView extends StatelessWidget {
  /// 表示する文言と操作。
  final EmptyStateSpec spec;

  /// 見出し上のアイコン（任意）。
  final IconData? icon;

  /// アイコンの大きさ（[icon] 指定時のみ有効）。
  final double iconSize;

  /// アイコンと操作ボタンの強調色（null ならテーマの primary）。
  final Color? accentColor;

  /// 見出しの文字スタイル（null ならテーマ既定）。
  final TextStyle? titleStyle;

  /// 説明の文字スタイル（null ならテーマ既定）。
  final TextStyle? descriptionStyle;

  /// Semantics の識別子（`sec_` 接頭辞）。
  final String semanticTestId;

  const EmptyStateView({
    required super.key,
    required this.spec,
    this.icon,
    this.iconSize = 48,
    this.accentColor,
    this.titleStyle,
    this.descriptionStyle,
    this.semanticTestId = 'sec_empty_state',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    final description = spec.description;
    final onAction = spec.onAction;
    final actionLabel = spec.actionLabel;

    return Semantics(
      identifier: semanticTestId,
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: accent),
              const SizedBox(height: 12),
            ],
            Text(
              spec.title,
              textAlign: TextAlign.center,
              style: titleStyle ?? theme.textTheme.titleMedium,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: descriptionStyle ?? theme.textTheme.bodySmall,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              SemanticHelper.interactive(
                testId: 'btn_empty_state_action',
                label: actionLabel,
                child: OutlinedButton(
                  key: const ValueKey('empty_state_action_button'),
                  style: OutlinedButton.styleFrom(foregroundColor: accent),
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
