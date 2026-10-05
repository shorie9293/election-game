import 'package:election_game/domain/models/glossary_term.dart';
import 'package:election_game/domain/services/glossary_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用の固定データ（catalog のコピーを部分集合として扱う）
List<GlossaryTerm> _sampleSource() {
  final ids = [
    'shokyosentyoku_sei',
    'hireidaihyo_sei',
    'kiken',
    'yoto',
    'deguchi_chosa',
  ];
  return [
    for (final id in ids) GlossaryService.findById(id)!,
  ];
}

void main() {
  group('catalog の整合性', () {
    test('14件以上の用語を収録する', () {
      expect(GlossaryService.catalog.length, greaterThanOrEqualTo(14));
    });

    test('必須14語をすべて含む', () {
      final terms = GlossaryService.catalog.map((t) => t.term).toSet();
      const required = [
        '小選挙区制',
        '比例代表制',
        '一票の格差',
        '棄権',
        '期日前投票',
        '出口調査',
        '世論調査',
        '与党',
        '野党',
        '連立',
        '内閣不信任決議',
        '選挙区',
        'マニフェスト',
        '得票率',
      ];
      for (final term in required) {
        expect(terms.contains(term), isTrue, reason: '$term が未収録');
      }
    });

    test('全件が空フィールドなし（必須4フィールド）', () {
      for (final t in GlossaryService.catalog) {
        expect(t.id, isNotEmpty, reason: t.id);
        expect(t.term, isNotEmpty, reason: t.id);
        expect(t.reading, isNotEmpty, reason: t.id);
        expect(t.category, isNotEmpty, reason: t.id);
      }
    });

    test('id に重複がない', () {
      final ids = GlossaryService.catalog.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('全 relatedTermIds が catalog 内に実在する', () {
      final ids = GlossaryService.catalog.map((t) => t.id).toSet();
      for (final t in GlossaryService.catalog) {
        for (final rel in t.relatedTermIds) {
          expect(ids.contains(rel), isTrue, reason: '${t.id} → $rel');
        }
      }
    });

    test('categories は初出順・重複なし・4種', () {
      final cats = GlossaryService.categories;
      expect(cats.toSet().length, cats.length);
      final expected = <String>[];
      for (final t in GlossaryService.catalog) {
        if (!expected.contains(t.category)) expected.add(t.category);
      }
      expect(cats, equals(expected));
      expect(cats.toSet(), equals({
        '選挙制度',
        '投票',
        '制度・議会',
        '調査・報道',
      }));
    });
  });

  group('allTerms / findById / relatedOf', () {
    test('allTerms は catalog のコピーを返す', () {
      final all = GlossaryService.allTerms();
      expect(all, hasLength(GlossaryService.catalog.length));
      expect(all.first, equals(GlossaryService.catalog.first));
      expect(identical(all, GlossaryService.catalog), isFalse);
    });

    test('findById は該当語を返し、未知IDは null', () {
      final t = GlossaryService.findById('kiken');
      expect(t, isNotNull);
      expect(t!.term, '棄権');
      expect(GlossaryService.findById('unknown_id'), isNull);
    });

    test('relatedOf は宣言順で解決する', () {
      final t = GlossaryService.findById('shokyosentyoku_sei')!;
      final rel = GlossaryService.relatedOf(t);
      expect(rel, isNotEmpty);
      for (final r in rel) {
        expect(t.relatedTermIds.contains(r.id), isTrue);
      }
      // 宣言順保持
      final relIds = rel.map((r) => r.id).toList();
      final filtered = t.relatedTermIds.where(relIds.contains).toList();
      expect(relIds, equals(filtered));
    });
  });

  group('normalize / matchesText / search', () {
    test('normalize は全角英数字・全角スペース・trim・小文字化を行う', () {
      expect(GlossaryService.normalize('ＭＰＬ　Ｔｅｓｔ '), 'mpl test');
      expect(GlossaryService.normalize('ＡＢ１２３'), 'ab123');
    });

    test('search は term でも reading でもヒットする', () {
      expect(GlossaryService.search('小選挙区制').map((t) => t.id),
          contains('shokyosentyoku_sei'));
      expect(GlossaryService.search('きけん').map((t) => t.id),
          contains('kiken'));
    });

    test('search は shortDefinition / description でもヒットする', () {
      // 一行定義「投票しないこと」に含まれる語句
      expect(GlossaryService.search('投票しないこと').map((t) => t.id),
          contains('kiken'));
      // 詳細解説の語句
      expect(GlossaryService.search('10日以内').map((t) => t.id),
          contains('naikai_fushin'));
    });

    test('search は全角英字クエリも正規化してヒットする', () {
      expect(
        GlossaryService.search('ＳＮＳ').map((t) => t.id),
        contains('yoron_chosa'),
      );
    });

    test('空クエリは全件を返す', () {
      expect(GlossaryService.search(''),
          hasLength(GlossaryService.catalog.length));
      expect(GlossaryService.search('   '),
          hasLength(GlossaryService.catalog.length));
    });

    test('matchesText の空クエリは true', () {
      final t = GlossaryService.findById('kiken')!;
      expect(GlossaryService.matchesText(t, ''), isTrue);
      expect(GlossaryService.matchesText(t, '存在しない語'), isFalse);
    });
  });

  group('filterByCategory', () {
    test('null / \'\' / \'すべて\' は全件を返す', () {
      final src = _sampleSource();
      expect(GlossaryService.filterByCategory(src, null), hasLength(src.length));
      expect(GlossaryService.filterByCategory(src, ''), hasLength(src.length));
      expect(GlossaryService.filterByCategory(src, 'すべて'),
          hasLength(src.length));
    });

    test('指定カテゴリのみ絞り込む', () {
      final src = _sampleSource();
      final result = GlossaryService.filterByCategory(src, '選挙制度');
      expect(result, isNotEmpty);
      for (final t in result) {
        expect(t.category, '選挙制度');
      }
    });
  });

  group('sortByName', () {
    test('reading 昇順に並ぶ', () {
      final sorted = GlossaryService.sortByName(GlossaryService.allTerms());
      for (var i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].reading.compareTo(sorted[i + 1].reading),
            lessThanOrEqualTo(0));
      }
    });

    test('同 reading 時は index タイブレークで安定する', () {
      final base = _sampleSource();
      final a = GlossaryService.sortByName(base);
      final b = GlossaryService.sortByName(a);
      // 再ソートしても順序が不変（完全なタイブレーク鎖）
      expect(b.map((t) => t.id).toList(), equals(a.map((t) => t.id).toList()));
      // 同じ id の複製でも元の並び順が保たれる（明示タイブレーク）
      final dup = [...base, ...base];
      final sortedDup = GlossaryService.sortByName(dup);
      final ids = sortedDup.map((t) => t.id).toList();
      for (final id in base.map((t) => t.id)) {
        expect(ids.where((e) => e == id).length, 2);
      }
      for (var i = 0; i < sortedDup.length - 1; i++) {
        final x = sortedDup[i];
        final y = sortedDup[i + 1];
        final cmp = x.reading.compareTo(y.reading) != 0
            ? x.reading.compareTo(y.reading)
            : (x.term.compareTo(y.term) != 0
                ? x.term.compareTo(y.term)
                : x.id.compareTo(y.id));
        expect(cmp, lessThanOrEqualTo(0));
      }
    });

    test('入力リストを破壊しない', () {
      final src = _sampleSource();
      final before = src.map((t) => t.id).toList();
      GlossaryService.sortByName(src);
      expect(src.map((t) => t.id).toList(), equals(before));
    });
  });

  group('sortByCategory', () {
    test('category 初出順 → 各カテゴリ内 reading 昇順・安定・非破壊', () {
      final src = _sampleSource();
      final before = src.map((t) => t.id).toList();
      final sorted = GlossaryService.sortByCategory(src);
      // 非破壊
      expect(src.map((t) => t.id).toList(), equals(before));

      final cats = GlossaryService.categories;
      // カテゴリ昇順ブロック
      for (var i = 0; i < sorted.length - 1; i++) {
        final ca = cats.indexOf(sorted[i].category);
        final cb = cats.indexOf(sorted[i + 1].category);
        expect(ca, lessThanOrEqualTo(cb));
        if (ca == cb) {
          expect(
              sorted[i].reading.compareTo(sorted[i + 1].reading),
              lessThanOrEqualTo(0));
        }
      }
      // 安定：再ソートで不変
      final again = GlossaryService.sortByCategory(sorted);
      expect(again.map((t) => t.id).toList(),
          equals(sorted.map((t) => t.id).toList()));
    });
  });

  group('apply の合成', () {
    test('検索 × カテゴリ × ソートが部分集合に正しく適用される', () {
      final src = _sampleSource();
      final result = GlossaryService.apply(
        src,
        query: '投票',
        category: '選挙制度',
      );
      // 各要素は両条件を満たす
      for (final t in result) {
        expect(GlossaryService.matchesText(t, '投票'), isTrue);
        expect(t.category, '選挙制度');
      }
      // 手動合成と同一結果
      final manual = GlossaryService.sortByName(
        GlossaryService.filterByCategory(
          src.where((t) => GlossaryService.matchesText(t, '投票')).toList(),
          '選挙制度',
        ),
      );
      expect(result.map((t) => t.id).toList(),
          equals(manual.map((t) => t.id).toList()));
      expect(result.length, manual.length);
    });

    test('categoryOrder ソートが使える', () {
      final result = GlossaryService.apply(
        _sampleSource(),
        category: null,
        sort: GlossarySortOrder.categoryOrder,
      );
      final cats = GlossaryService.categories;
      for (var i = 0; i < result.length - 1; i++) {
        expect(
            cats.indexOf(result[i].category),
            lessThanOrEqualTo(cats.indexOf(result[i + 1].category)));
      }
    });

    test('入力リストを破壊しない', () {
      final src = _sampleSource();
      final before = src.map((t) => t.id).toList();
      GlossaryService.apply(src, query: '投票', category: '選挙制度');
      expect(src.map((t) => t.id).toList(), equals(before));
    });
  });
}
