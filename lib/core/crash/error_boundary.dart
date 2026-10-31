import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/testing/app_keys.dart';

/// 表示中の例外を受け止める境界。
///
/// `ErrorWidget.builder` を差し替え、子ツリーの build 中に起きた例外を
/// 「表示中に問題が発生しました」＋「再読み込み」の日本語UIへ置き換える。
/// 再読み込みは子ツリーを作り直す（[generation] を進める）。
///
/// 注意: `ErrorWidget.builder` はプロセス全体で1つしかないため、
/// [dispose] で必ず元へ戻す。既存の `MaterialApp` 構成は変更しない。
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.fallbackBuilder,
  });

  /// 守るべき子ツリー。
  final Widget child;

  /// 例外発生時の通知（クラッシュログへの記録など）。
  final void Function(FlutterErrorDetails details)? onError;

  /// 差し替え用のフォールバック。未指定なら既定の日本語UI。
  final Widget Function(FlutterErrorDetails details)? fallbackBuilder;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  ErrorWidgetBuilder? _previousBuilder;
  FlutterErrorDetails? _details;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _previousBuilder = ErrorWidget.builder;
    ErrorWidget.builder = _handleErrorWidget;
  }

  @override
  void dispose() {
    final previous = _previousBuilder;
    if (previous != null) {
      ErrorWidget.builder = previous;
    }
    super.dispose();
  }

  Widget _handleErrorWidget(FlutterErrorDetails details) {
    try {
      widget.onError?.call(details);
    } catch (_) {
      // 記録側の失敗でフォールバック表示を妨げない。
    }
    _markBroken(details);
    return _buildFallback(details);
  }

  /// 壊れたことを記録する。build 中は setState できないため次のフレームで行う。
  void _markBroken(FlutterErrorDetails details) {
    if (_details != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _details != null) return;
      setState(() => _details = details);
    });
  }

  void _reload() {
    setState(() {
      _details = null;
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    if (details != null) {
      return widget.fallbackBuilder?.call(details) ?? _buildFallback(details);
    }
    // generation を進めると子ツリーが KeyedSubtree ごと作り直される。
    return KeyedSubtree(
      key: ValueKey<int>(_generation),
      child: widget.child,
    );
  }

  Widget _buildFallback(FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFFDF6EC),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFB03A2E),
                ),
                const SizedBox(height: 16),
                const Text(
                  '表示中に問題が発生しました',
                  key: AppKeys.errorBoundaryFallback,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '記録に残しました。困ったときは設定の「不具合の報告」から'
                  '内容をコピーしてご連絡ください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF4A3B2A)),
                ),
                const SizedBox(height: 24),
                SemanticHelper.interactive(
                  testId: 'btn_error_boundary_reload',
                  label: '再読み込み',
                  child: ElevatedButton(
                    key: AppKeys.errorBoundaryReloadButton,
                    onPressed: _reload,
                    child: const Text('再読み込み'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
