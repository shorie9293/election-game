import 'package:flutter/services.dart';

/// 軽い触覚フィードバック（タップ確定時など）。
///
/// 戻り値を await してはならない。flutter_test ではプラットフォームチャネルが
/// 解決されず Future が永久に完了しないため、`ignore()` で投げっぱなしにする。
void hapticTap() => HapticFeedback.selectionClick().ignore();
