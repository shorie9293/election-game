// 削除Undo（元に戻す）の純粋ドメイン試練。
//
// UndoBuffer は「一度だけ取り出す」ことで二重復元を構造的に防ぐ。
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/undo/domain/undo_buffer.dart';

void main() {
  group('UndoBuffer', () {
    test('初期状態は canUndo=false / take・peek は null', () {
      final buffer = UndoBuffer<String>();
      expect(buffer.canUndo, isFalse);
      expect(buffer.peek(), isNull);
      expect(buffer.take(), isNull);
    });

    test('push すると canUndo=true になり peek で中身が見える', () {
      final buffer = UndoBuffer<String>();
      buffer.push('誤答ノートA');
      expect(buffer.canUndo, isTrue);
      expect(buffer.peek(), '誤答ノートA');
    });

    test('take は一度だけ値を返し、二度目は null（二重復元防止）', () {
      final buffer = UndoBuffer<String>();
      buffer.push('誤答ノートA');
      expect(buffer.take(), '誤答ノートA');
      expect(buffer.take(), isNull);
      expect(buffer.canUndo, isFalse);
      expect(buffer.peek(), isNull);
    });

    test('push の連続は最新のみ保持し、押し出された旧値を返す', () {
      final buffer = UndoBuffer<String>();
      expect(buffer.push('first'), isNull);
      expect(buffer.push('second'), 'first');
      expect(buffer.peek(), 'second');
      expect(buffer.take(), 'second');
      expect(buffer.take(), isNull);
    });

    test('clear で破棄され canUndo=false / take は null', () {
      final buffer = UndoBuffer<String>();
      buffer.push('誤答ノートA');
      buffer.clear();
      expect(buffer.canUndo, isFalse);
      expect(buffer.take(), isNull);
    });

    test('リストを保持でき、取り出した中身と並びが保たれる', () {
      final buffer = UndoBuffer<List<String>>();
      buffer.push(['a', 'b']);
      expect(buffer.take(), ['a', 'b']);
      expect(buffer.canUndo, isFalse);
    });
  });
}
