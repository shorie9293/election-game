import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart';

/// 読み込み失敗の表示。0件（[LoadEmptyView]）とは別ウィジェット。
///
/// [onRetry] が null のときは再試行ボタンを出さない（再試行不能な失敗）。
class LoadErrorView extends StatelessWidget {
  /// 利用者向けの失敗文言。空文字は不可。
  final String message;

  /// 再試行処理。null なら再試行ボタン非表示。
  final VoidCallback? onRetry;

  const LoadErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Container(
      key: const ValueKey('load_error_view'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (retry != null) ...[
            const SizedBox(height: 12),
            SemanticHelper.interactive(
              testId: 'btn_load_retry',
              label: '再試行',
              child: OutlinedButton(
                key: const ValueKey('load_retry_button'),
                onPressed: retry,
                child: const Text('再試行'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 読み込みは成功したが0件であることの表示。
///
/// 失敗を意味しないため再試行ボタンを持たない。
class LoadEmptyView extends StatelessWidget {
  /// 利用者向けの空状態文言。空文字は不可。
  final String message;

  const LoadEmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('load_empty_view'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 32),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
