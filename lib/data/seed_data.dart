/// Seed content: full gojūon (base + dakuten + handakuten) for hiragana and
/// katakana, plus a starter set of JLPT N5 kanji.
///
/// ponytail: yōon combos (きゃ, しゅ …) skipped — add rows here when needed,
/// the schema and UI already handle arbitrary characters.
library;

/// (symbol, reading, rowLabel)
typedef KanaSeed = (String, String, String);

const List<KanaSeed> _hira = [
  ('あ', 'a', 'a'), ('い', 'i', 'a'), ('う', 'u', 'a'), ('え', 'e', 'a'), ('お', 'o', 'a'),
  ('か', 'ka', 'k'), ('き', 'ki', 'k'), ('く', 'ku', 'k'), ('け', 'ke', 'k'), ('こ', 'ko', 'k'),
  ('さ', 'sa', 's'), ('し', 'shi', 's'), ('す', 'su', 's'), ('せ', 'se', 's'), ('そ', 'so', 's'),
  ('た', 'ta', 't'), ('ち', 'chi', 't'), ('つ', 'tsu', 't'), ('て', 'te', 't'), ('と', 'to', 't'),
  ('な', 'na', 'n'), ('に', 'ni', 'n'), ('ぬ', 'nu', 'n'), ('ね', 'ne', 'n'), ('の', 'no', 'n'),
  ('は', 'ha', 'h'), ('ひ', 'hi', 'h'), ('ふ', 'fu', 'h'), ('へ', 'he', 'h'), ('ほ', 'ho', 'h'),
  ('ま', 'ma', 'm'), ('み', 'mi', 'm'), ('む', 'mu', 'm'), ('め', 'me', 'm'), ('も', 'mo', 'm'),
  ('や', 'ya', 'y'), ('ゆ', 'yu', 'y'), ('よ', 'yo', 'y'),
  ('ら', 'ra', 'r'), ('り', 'ri', 'r'), ('る', 'ru', 'r'), ('れ', 're', 'r'), ('ろ', 'ro', 'r'),
  ('わ', 'wa', 'w'), ('を', 'wo', 'w'), ('ん', 'n', 'w'),
  // dakuten / handakuten
  ('が', 'ga', 'g'), ('ぎ', 'gi', 'g'), ('ぐ', 'gu', 'g'), ('げ', 'ge', 'g'), ('ご', 'go', 'g'),
  ('ざ', 'za', 'z'), ('じ', 'ji', 'z'), ('ず', 'zu', 'z'), ('ぜ', 'ze', 'z'), ('ぞ', 'zo', 'z'),
  ('だ', 'da', 'd'), ('ぢ', 'ji', 'd'), ('づ', 'zu', 'd'), ('で', 'de', 'd'), ('ど', 'do', 'd'),
  ('ば', 'ba', 'b'), ('び', 'bi', 'b'), ('ぶ', 'bu', 'b'), ('べ', 'be', 'b'), ('ぼ', 'bo', 'b'),
  ('ぱ', 'pa', 'p'), ('ぴ', 'pi', 'p'), ('ぷ', 'pu', 'p'), ('ぺ', 'pe', 'p'), ('ぽ', 'po', 'p'),
];

const List<KanaSeed> _kata = [
  ('ア', 'a', 'a'), ('イ', 'i', 'a'), ('ウ', 'u', 'a'), ('エ', 'e', 'a'), ('オ', 'o', 'a'),
  ('カ', 'ka', 'k'), ('キ', 'ki', 'k'), ('ク', 'ku', 'k'), ('ケ', 'ke', 'k'), ('コ', 'ko', 'k'),
  ('サ', 'sa', 's'), ('シ', 'shi', 's'), ('ス', 'su', 's'), ('セ', 'se', 's'), ('ソ', 'so', 's'),
  ('タ', 'ta', 't'), ('チ', 'chi', 't'), ('ツ', 'tsu', 't'), ('テ', 'te', 't'), ('ト', 'to', 't'),
  ('ナ', 'na', 'n'), ('ニ', 'ni', 'n'), ('ヌ', 'nu', 'n'), ('ネ', 'ne', 'n'), ('ノ', 'no', 'n'),
  ('ハ', 'ha', 'h'), ('ヒ', 'hi', 'h'), ('フ', 'fu', 'h'), ('ヘ', 'he', 'h'), ('ホ', 'ho', 'h'),
  ('マ', 'ma', 'm'), ('ミ', 'mi', 'm'), ('ム', 'mu', 'm'), ('メ', 'me', 'm'), ('モ', 'mo', 'm'),
  ('ヤ', 'ya', 'y'), ('ユ', 'yu', 'y'), ('ヨ', 'yo', 'y'),
  ('ラ', 'ra', 'r'), ('リ', 'ri', 'r'), ('ル', 'ru', 'r'), ('レ', 're', 'r'), ('ロ', 'ro', 'r'),
  ('ワ', 'wa', 'w'), ('ヲ', 'wo', 'w'), ('ン', 'n', 'w'),
  ('ガ', 'ga', 'g'), ('ギ', 'gi', 'g'), ('グ', 'gu', 'g'), ('ゲ', 'ge', 'g'), ('ゴ', 'go', 'g'),
  ('ザ', 'za', 'z'), ('ジ', 'ji', 'z'), ('ズ', 'zu', 'z'), ('ゼ', 'ze', 'z'), ('ゾ', 'zo', 'z'),
  ('ダ', 'da', 'd'), ('ヂ', 'ji', 'd'), ('ヅ', 'zu', 'd'), ('デ', 'de', 'd'), ('ド', 'do', 'd'),
  ('バ', 'ba', 'b'), ('ビ', 'bi', 'b'), ('ブ', 'bu', 'b'), ('ベ', 'be', 'b'), ('ボ', 'bo', 'b'),
  ('パ', 'pa', 'p'), ('ピ', 'pi', 'p'), ('プ', 'pu', 'p'), ('ペ', 'pe', 'p'), ('ポ', 'po', 'p'),
];

/// (symbol, reading, meaning)
/// The full JLPT N5 set — all 103 kanji from "The First 103 Kanji"
/// (Nihongo Ichiban), in the book's order.
const List<(String, String, String)> _kanji = [
  ('一', 'ichi', 'one'), ('二', 'ni', 'two'), ('三', 'san', 'three'),
  ('四', 'shi', 'four'), ('五', 'go', 'five'), ('六', 'roku', 'six'),
  ('七', 'shichi', 'seven'), ('八', 'hachi', 'eight'), ('九', 'kyū', 'nine'),
  ('十', 'jū', 'ten'), ('百', 'hyaku', 'hundred'), ('千', 'sen', 'thousand'),
  ('万', 'man', 'ten thousand'),
  ('水', 'mizu', 'water'), ('火', 'hi', 'fire'), ('木', 'ki', 'tree'),
  ('天', 'ten', 'heaven'), ('土', 'tsuchi', 'earth'), ('北', 'kita', 'north'),
  ('東', 'higashi', 'east'), ('西', 'nishi', 'west'), ('南', 'minami', 'south'),
  ('左', 'hidari', 'left'), ('右', 'migi', 'right'),
  ('日', 'nichi', 'day / sun'), ('月', 'getsu', 'moon / month'),
  ('花', 'hana', 'flower'), ('魚', 'sakana', 'fish'), ('空', 'sora', 'sky'),
  ('山', 'yama', 'mountain'), ('川', 'kawa', 'river'), ('雨', 'ame', 'rain'),
  ('本', 'hon', 'book / origin'), ('目', 'me', 'eye'), ('口', 'kuchi', 'mouth'),
  ('耳', 'mimi', 'ear'), ('手', 'te', 'hand'), ('足', 'ashi', 'foot / leg'),
  ('人', 'hito', 'person'), ('母', 'haha', 'mother'), ('父', 'chichi', 'father'),
  ('女', 'onna', 'woman'), ('男', 'otoko', 'man'), ('子', 'ko', 'child'),
  ('小', 'chiisai', 'small'), ('中', 'naka', 'middle / inside'),
  ('大', 'ōkii', 'big'), ('上', 'ue', 'up / above'), ('下', 'shita', 'down / below'),
  ('何', 'nani', 'what'), ('行', 'iku', 'to go'), ('見', 'miru', 'to see'),
  ('言', 'iu', 'to say'), ('語', 'go', 'language'), ('食', 'taberu', 'eat / food'),
  ('飲', 'nomu', 'to drink'), ('会', 'au', 'to meet'), ('学', 'gaku', 'study'),
  ('休', 'yasumu', 'to rest'), ('買', 'kau', 'to buy'),
  ('聞', 'kiku', 'to listen / ask'), ('来', 'kuru', 'to come'),
  ('立', 'tatsu', 'to stand'), ('生', 'sei', 'life / birth'),
  ('話', 'hanasu', 'to speak'), ('出', 'deru', 'to exit'), ('読', 'yomu', 'to read'),
  ('入', 'hairu', 'to enter'), ('書', 'kaku', 'to write'),
  ('後', 'ato', 'after / behind'), ('古', 'furui', 'old'),
  ('高', 'takai', 'tall / expensive'), ('安', 'yasui', 'cheap / safe'),
  ('多', 'ōi', 'many'), ('新', 'atarashii', 'new'), ('少', 'sukunai', 'few'),
  ('長', 'nagai', 'long'), ('白', 'shiroi', 'white'),
  ('分', 'fun', 'minute / divide'), ('時', 'ji', 'hour / time'),
  ('間', 'aida', 'interval / between'), ('週', 'shū', 'week'), ('年', 'nen', 'year'),
  ('今', 'ima', 'now'), ('先', 'saki', 'previous / ahead'),
  ('前', 'mae', 'before / front'), ('午', 'go', 'noon'), ('半', 'han', 'half'),
  ('店', 'mise', 'shop'), ('外', 'soto', 'outside'), ('電', 'den', 'electricity'),
  ('道', 'michi', 'road / way'), ('毎', 'mai', 'every'), ('友', 'tomo', 'friend'),
  ('名', 'na', 'name'), ('金', 'kin', 'gold / money'), ('円', 'en', 'yen / circle'),
  ('車', 'kuruma', 'car / vehicle'), ('駅', 'eki', 'station'),
  ('気', 'ki', 'spirit / energy'), ('国', 'kuni', 'country'),
  ('社', 'sha', 'company / shrine'), ('校', 'kō', 'school'),
];

/// Rows ready for insertion into the `characters` table.
List<Map<String, Object?>> seedRows() {
  final rows = <Map<String, Object?>>[];
  var order = 0;
  for (final (symbol, reading, row) in _hira) {
    rows.add({
      'type': 'hiragana', 'symbol': symbol, 'reading': reading,
      'meaning': null, 'row_label': row, 'order_index': order++,
    });
  }
  order = 0;
  for (final (symbol, reading, row) in _kata) {
    rows.add({
      'type': 'katakana', 'symbol': symbol, 'reading': reading,
      'meaning': null, 'row_label': row, 'order_index': order++,
    });
  }
  order = 0;
  for (final (symbol, reading, meaning) in _kanji) {
    rows.add({
      'type': 'kanji', 'symbol': symbol, 'reading': reading,
      'meaning': meaning, 'row_label': 'kanji', 'order_index': order++,
    });
  }
  return rows;
}
