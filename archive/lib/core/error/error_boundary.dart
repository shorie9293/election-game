import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 全画面を包むエラー境界。
/// 捕捉不能な例外発生時に、クラッシュせずフォールバックUIを表示する。
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      setState(() {
        _error = details.exception;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚠ 禍津発生',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_error',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

/// GameScreen等で使う簡易ErrorBoundary Widget版
class ErrorBoundaryWidget extends StatelessWidget {
  final Widget child;

  const ErrorBoundaryWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
