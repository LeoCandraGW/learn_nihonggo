import 'dart:convert';
import 'dart:ui';

/// A single teachable glyph: kana or kanji.
class Character {
  final int id;
  final String type; // 'hiragana' | 'katakana' | 'kanji'
  final String symbol; // あ / ア / 一
  final String reading; // romaji for kana; primary reading for kanji
  final String? meaning; // kanji only
  final String rowLabel; // gojūon row ('a','k',...) or kanji group
  final int orderIndex;

  const Character({
    required this.id,
    required this.type,
    required this.symbol,
    required this.reading,
    required this.meaning,
    required this.rowLabel,
    required this.orderIndex,
  });

  factory Character.fromMap(Map<String, Object?> m) => Character(
        id: m['id'] as int,
        type: m['type'] as String,
        symbol: m['symbol'] as String,
        reading: m['reading'] as String,
        meaning: m['meaning'] as String?,
        rowLabel: m['row_label'] as String,
        orderIndex: m['order_index'] as int,
      );
}

/// Leitner spaced-repetition state for one character.
class Progress {
  final int box; // 0..4, higher = better known
  final int correct;
  final int incorrect;
  final int? lastReviewed; // epoch ms
  final int dueAt; // epoch ms; 0 = never studied (due now)

  const Progress({
    this.box = 0,
    this.correct = 0,
    this.incorrect = 0,
    this.lastReviewed,
    this.dueAt = 0,
  });

  bool get mastered => box >= 4;

  factory Progress.fromMap(Map<String, Object?> m) => Progress(
        box: m['box'] as int,
        correct: m['correct'] as int,
        incorrect: m['incorrect'] as int,
        lastReviewed: m['last_reviewed'] as int?,
        dueAt: m['due_at'] as int,
      );
}

/// A saved handwriting attempt. Strokes are normalized to 0..1 so a drawing
/// captured on any screen size replays correctly on any other.
class DrawingData {
  final List<List<Offset>> strokes;

  const DrawingData(this.strokes);

  bool get isEmpty => strokes.every((s) => s.isEmpty);

  String toJson() => jsonEncode(strokes
      .map((s) => s.map((p) => [p.dx, p.dy]).toList())
      .toList());

  factory DrawingData.fromJson(String s) {
    final raw = jsonDecode(s) as List;
    return DrawingData(raw
        .map((stroke) => (stroke as List)
            .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList())
        .toList());
  }
}
