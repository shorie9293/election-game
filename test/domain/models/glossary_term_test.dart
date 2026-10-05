import 'package:election_game/domain/models/glossary_term.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlossaryTerm コンストラクタ', () {
    test('id が空なら ArgumentError を投げる', () {
      expect(
        () => GlossaryTerm(
          id: '',
          term: '用語',
          reading: 'ようご',
          category: '選挙制度',
        ),
        throwsArgumentError,
      );
    });

    test('term が空なら ArgumentError を投げる', () {
      expect(
        () => GlossaryTerm(
          id: 'kogai',
          term: '',
          reading: 'ようご',
          category: '選挙制度',
        ),
        throwsArgumentError,
      );
    });

    test('デフォルト引数が適用される', () {
      final t = GlossaryTerm(
        id: 'kogai',
        term: '用語',
        reading: 'ようご',
        category: '選挙制度',
      );
      expect(t.shortDefinition, '');
      expect(t.description, '');
      expect(t.relatedTermIds, isEmpty);
    });
  });

  group('copyWith / == / hashCode', () {
    final base = GlossaryTerm(
      id: 'kogai',
      term: '用語',
      reading: 'ようご',
      category: '選挙制度',
      shortDefinition: '一行',
      description: '詳しい',
      relatedTermIds: ['a', 'b'],
    );

    test('copyWith は指定フィールドのみ差し替える', () {
      final copied = base.copyWith(term: '別語');
      expect(copied.term, '別語');
      expect(copied.id, base.id);
      expect(copied.reading, base.reading);
      expect(copied.category, base.category);
      expect(copied.shortDefinition, base.shortDefinition);
      expect(copied.description, base.description);
      expect(copied.relatedTermIds, base.relatedTermIds);
    });

    test('同フィールドは等価・hashCode も一致', () {
      final twin = base.copyWith(relatedTermIds: ['a', 'b']);
      expect(twin, equals(base));
      expect(twin.hashCode, base.hashCode);
    });

    test('異なるフィールドがあれば非等価', () {
      expect(base == base.copyWith(description: '違う'), isFalse);
      expect(base == base.copyWith(relatedTermIds: ['a']), isFalse);
    });
  });
}
