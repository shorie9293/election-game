import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib 配下に残ってよい「本番で垂れ流れるログ」の総数。
///
/// 移行前 16 → 移行後 1（唯一の残置は AppLogger 内部の既定 sink）。
/// AppLogger 以外に print/debugPrint を足したらこの試練が赤くなる。
const int _baseline = 1;

/// 唯一の残置が許されるファイル（ロガーの既定 sink）。
const String _sanctionedFile = 'lib/core/logging/app_logger.dart';

final RegExp _printCall = RegExp(r'\b(debugPrint|print)\s*\(');

void main() {
  test('lib 配下の print/debugPrint は baseline($_baseline) 以下', () {
    final baselineFile = File('tool/print_baseline.txt');
    expect(
      baselineFile.existsSync(),
      isTrue,
      reason: 'tool/print_baseline.txt が見つからない（作業ディレクトリはパッケージ直下であること）',
    );
    final recorded =
        int.parse(baselineFile.readAsStringSync().trim().split('\n').first);
    expect(recorded, _baseline, reason: 'baseline ファイルと試練の定数が乖離している');

    final hits = <String>[];
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'lib が見つからない');

    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_printCall.hasMatch(lines[i])) {
          hits.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      hits.length,
      lessThanOrEqualTo(_baseline),
      reason: '本番ログの垂れ流しが ${hits.length - _baseline} 件増えた。'
          'appLog（lib/core/logging/app_logger.dart）へ移行せよ:\n'
          '${hits.join('\n')}',
    );

    final outside = hits.where((h) => !h.startsWith(_sanctionedFile)).toList();
    expect(
      outside,
      isEmpty,
      reason: 'ロガー以外に print/debugPrint が残っている。appLog へ移行せよ:\n'
          '${outside.join('\n')}',
    );
  });
}
