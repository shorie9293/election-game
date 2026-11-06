/// かな表記ゆれ吸収のための純粋関数。
///
/// 検索比較用に、ひらがなをカタカナへ、半角カタカナを全角カタカナへ畳み込む。
/// 全角カタカナ・ASCII・漢字などは変更しない。冪等（foldKana(foldKana(s)) == foldKana(s)）。
library;

/// 半角カタカナ（U+FF66..U+FF9D）→ 全角カタカナの表引き。
const Map<int, String> _halfWidthKana = {
  0xFF66: 'ヲ',
  0xFF67: 'ァ',
  0xFF68: 'ィ',
  0xFF69: 'ゥ',
  0xFF6A: 'ェ',
  0xFF6B: 'ォ',
  0xFF6C: 'ャ',
  0xFF6D: 'ュ',
  0xFF6E: 'ョ',
  0xFF6F: 'ッ',
  0xFF70: 'ー',
  0xFF71: 'ア',
  0xFF72: 'イ',
  0xFF73: 'ウ',
  0xFF74: 'エ',
  0xFF75: 'オ',
  0xFF76: 'カ',
  0xFF77: 'キ',
  0xFF78: 'ク',
  0xFF79: 'ケ',
  0xFF7A: 'コ',
  0xFF7B: 'サ',
  0xFF7C: 'シ',
  0xFF7D: 'ス',
  0xFF7E: 'セ',
  0xFF7F: 'ソ',
  0xFF80: 'タ',
  0xFF81: 'チ',
  0xFF82: 'ツ',
  0xFF83: 'テ',
  0xFF84: 'ト',
  0xFF85: 'ナ',
  0xFF86: 'ニ',
  0xFF87: 'ヌ',
  0xFF88: 'ネ',
  0xFF89: 'ノ',
  0xFF8A: 'ハ',
  0xFF8B: 'ヒ',
  0xFF8C: 'フ',
  0xFF8D: 'ヘ',
  0xFF8E: 'ホ',
  0xFF8F: 'マ',
  0xFF90: 'ミ',
  0xFF91: 'ム',
  0xFF92: 'メ',
  0xFF93: 'モ',
  0xFF94: 'ヤ',
  0xFF95: 'ユ',
  0xFF96: 'ヨ',
  0xFF97: 'ラ',
  0xFF98: 'リ',
  0xFF99: 'ル',
  0xFF9A: 'レ',
  0xFF9B: 'ロ',
  0xFF9C: 'ワ',
  0xFF9D: 'ン',
};

/// 濁点（U+FF9E）を合成した全角カタカナ。
const Map<String, String> _dakuten = {
  'ウ': 'ヴ',
  'カ': 'ガ',
  'キ': 'ギ',
  'ク': 'グ',
  'ケ': 'ゲ',
  'コ': 'ゴ',
  'サ': 'ザ',
  'シ': 'ジ',
  'ス': 'ズ',
  'セ': 'ゼ',
  'ソ': 'ゾ',
  'タ': 'ダ',
  'チ': 'ヂ',
  'ツ': 'ヅ',
  'テ': 'デ',
  'ト': 'ド',
  'ハ': 'バ',
  'ヒ': 'ビ',
  'フ': 'ブ',
  'ヘ': 'ベ',
  'ホ': 'ボ',
  'ワ': 'ヷ',
  'ヲ': 'ヺ',
};

/// 半濁点（U+FF9F）を合成した全角カタカナ。
const Map<String, String> _handakuten = {
  'ハ': 'パ',
  'ヒ': 'ピ',
  'フ': 'プ',
  'ヘ': 'ペ',
  'ホ': 'ポ',
};

/// ひらがな（U+3041..U+3096）をカタカナへ畳み込む。
///
/// - ひらがな U+3041–U+3096 → +0x60（ゕ/ゖ を含む）
/// - 半角カタカナ U+FF66–FF9F → 全角カタカナ（濁点・半濁点は前字へ合成）
/// - 全角カタカナ・ASCII・漢字は不変
String foldKana(String input) {
  final out = <String>[];
  for (final rune in input.runes) {
    if (rune >= 0x3041 && rune <= 0x3096) {
      // ひらがな → カタカナ
      out.add(String.fromCharCode(rune + 0x60));
      continue;
    }

    final mapped = _halfWidthKana[rune];
    if (mapped != null) {
      out.add(mapped);
      continue;
    }

    if (rune == 0xFF9E || rune == 0xFF9F) {
      final isDakuten = rune == 0xFF9E;
      if (out.isNotEmpty) {
        final base = out.last;
        final combined = isDakuten ? _dakuten[base] : _handakuten[base];
        if (combined != null) {
          out[out.length - 1] = combined;
          continue;
        }
      }
      // 結合できない孤立した濁点・半濁点は全角のそれへ
      out.add(isDakuten ? '゛' : '゜');
      continue;
    }

    out.add(String.fromCharCode(rune));
  }
  return out.join();
}
