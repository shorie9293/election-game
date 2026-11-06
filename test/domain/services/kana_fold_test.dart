import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/text/kana_fold.dart';
import 'package:election_game/domain/services/glossary_service.dart';

void main() {
  group('foldKana', () {
    test('ひらがなをカタカナへ畳み込む', () {
      expect(foldKana('まにふぇすと'), 'マニフェスト');
      expect(foldKana('よろんちょうさ'), 'ヨロンチョウサ');
      expect(foldKana('あいうえお'), 'アイウエオ');
    });

    test('半角カナを全角カナへ変換し濁点・半濁点を合成する', () {
      expect(foldKana('ｶﾞｯｺｳ'), 'ガッコウ');
      expect(foldKana('ﾊﾟﾝ'), 'パン');
      expect(foldKana('ｳﾞ'), 'ヴ');
      expect(foldKana('ﾌﾟ'), 'プ');
      expect(foldKana('ﾏﾆﾌｪｽﾄ'), 'マニフェスト');
      expect(foldKana('ｰ'), 'ー');
    });

    test('全角カタカナは不変', () {
      expect(foldKana('マニフェスト'), 'マニフェスト');
      expect(foldKana('ヴァイオリン'), 'ヴァイオリン');
    });

    test('ASCII・漢字は不変', () {
      expect(foldKana('Manifesto 123 ABC'), 'Manifesto 123 ABC');
      expect(foldKana('選挙区'), '選挙区');
      expect(foldKana(''), '');
    });

    test('冪等である', () {
      const mixed = 'まにふぇすとｶﾞｯｺｳＡＢＣ選挙';
      final once = foldKana(mixed);
      expect(foldKana(once), once);
    });

    test('ヶ・ゖ を含むひらがなを畳み込む', () {
      expect(foldKana('ゕゖ'), 'ヵヶ');
      expect(foldKana('ヶ'), 'ヶ');
      expect(foldKana('ゖ'), 'ヶ');
    });
  });

  group('統合: 用語集検索のかな表記ゆれ吸収', () {
    final manifesto = GlossaryService.findById('manifesto')!;

    test('ひらがな入力でカタカナ用語にヒットする', () {
      expect(GlossaryService.matchesText(manifesto, 'まにふぇすと'), isTrue);
      expect(GlossaryService.search('まにふぇすと').map((t) => t.id),
          contains('manifesto'));
    });

    test('カタカナ入力でひらがな reading にもヒットする', () {
      expect(GlossaryService.matchesText(manifesto, 'マニフェスト'), isTrue);
      expect(GlossaryService.search('マニフェスト').map((t) => t.id),
          contains('manifesto'));
    });

    test('半角カナ入力でもヒットする', () {
      expect(GlossaryService.matchesText(manifesto, 'ﾏﾆﾌｪｽﾄ'), isTrue);
      expect(GlossaryService.search('ﾏﾆﾌｪｽﾄ').map((t) => t.id),
          contains('manifesto'));
    });

    test('既存の matchesText 意味論（部分一致・空クエリ・非ヒット）は不変', () {
      expect(GlossaryService.matchesText(manifesto, ''), isTrue);
      expect(GlossaryService.matchesText(manifesto, 'マニ'), isTrue);
      expect(GlossaryService.matchesText(manifesto, '存在しない語'), isFalse);
      // normalize の既存戻り値も不変
      expect(GlossaryService.normalize('ＭＰＬ　Ｔｅｓｔ '), 'mpl test');
    });
  });
}
