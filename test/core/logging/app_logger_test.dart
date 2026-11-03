import 'package:election_game/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    late List<String> lines;
    late AppLogger logger;

    void capture({required bool isDebug}) {
      lines = <String>[];
      logger = AppLogger(isDebug: isDebug, sink: lines.add);
    }

    test('debug は isDebug=false で無出力', () {
      capture(isDebug: false);
      logger.debug('選挙結果: 当選');
      expect(lines, isEmpty);
    });

    test('info は isDebug=false で無出力', () {
      capture(isDebug: false);
      logger.info('支持率 42.0%');
      expect(lines, isEmpty);
    });

    test('debug は isDebug=true で DEBUG タグ付きで出力', () {
      capture(isDebug: true);
      logger.debug('ユーザー選択: 政策A');
      expect(lines, hasLength(1));
      expect(lines.single, contains('DEBUG'));
      expect(lines.single, contains('ユーザー選択: 政策A'));
    });

    test('info は isDebug=true で INFO タグ付きで出力', () {
      capture(isDebug: true);
      logger.info('支持率 42.0%');
      expect(lines, hasLength(1));
      expect(lines.single, contains('INFO'));
      expect(lines.single, contains('支持率 42.0%'));
    });

    test('warn は isDebug=false でも WARN タグ付きで常時出力', () {
      capture(isDebug: false);
      logger.warn('保存に失敗');
      expect(lines, hasLength(1));
      expect(lines.single, contains('WARN'));
      expect(lines.single, contains('保存に失敗'));
    });

    test('error は isDebug=false でも ERROR タグ・例外詳細付きで常時出力', () {
      capture(isDebug: false);
      final stack = StackTrace.current;
      logger.error('通知初期化に失敗', StateError('boom'), stack);
      expect(lines, hasLength(1));
      expect(lines.single, contains('ERROR'));
      expect(lines.single, contains('通知初期化に失敗'));
      expect(lines.single, contains('boom'));
      expect(lines.single, contains('stack'));
    });

    test('sink が throw しても呼び出し側へ例外を伝播しない', () {
      final boom = AppLogger(
        isDebug: true,
        sink: (_) => throw StateError('sink failure'),
      );
      expect(() => boom.debug('x'), returnsNormally);
      expect(() => boom.info('x'), returnsNormally);
      expect(() => boom.warn('x'), returnsNormally);
      expect(() => boom.error('x'), returnsNormally);
    });

    test('レベルタグは相互に区別できる', () {
      final tags = <String>[];
      final tagged = AppLogger(
        isDebug: true,
        sink: (line) => tags.add(line.split(']').first),
      );
      tagged.debug('d');
      tagged.info('i');
      tagged.warn('w');
      tagged.error('e');
      expect(tags.toSet(), hasLength(4));
    });

    test('appLog は既定の AppLogger インスタンス', () {
      expect(appLog, isA<AppLogger>());
    });
  });
}
