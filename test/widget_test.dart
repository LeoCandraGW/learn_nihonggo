import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_nihonggo/data/models.dart';
import 'package:learn_nihonggo/data/seed_data.dart';
import 'package:learn_nihonggo/features/review/recognizer.dart';

void main() {
  test('DrawingData survives a JSON round-trip', () {
    const d = DrawingData([
      [Offset(0.1, 0.2), Offset(0.3, 0.4)],
      [Offset(0.5, 0.6)],
    ]);
    final back = DrawingData.fromJson(d.toJson());
    expect(back.strokes.length, 2);
    expect(back.strokes[0][1], const Offset(0.3, 0.4));
    expect(back.strokes[1].single, const Offset(0.5, 0.6));
  });

  test('empty drawing is detected', () {
    expect(const DrawingData([[], []]).isEmpty, isTrue);
    expect(const DrawingData([[Offset.zero]]).isEmpty, isFalse);
  });

  test('seed covers both kana sets and kanji with unique per-type ordering', () {
    final rows = seedRows();
    final byType = <String, List<int>>{};
    for (final r in rows) {
      byType.putIfAbsent(r['type'] as String, () => []).add(r['order_index'] as int);
    }
    expect(byType.keys.toSet(), {'hiragana', 'katakana', 'kanji'});
    for (final orders in byType.values) {
      expect(orders, List.generate(orders.length, (i) => i)); // 0..n-1, no gaps
    }
  });

  test('maskF1: identical=1, disjoint=0, half-overlap in between', () {
    final full = Uint8List.fromList([1, 1, 1, 1]);
    expect(maskF1(full, full), 1.0);
    expect(maskF1(full, Uint8List.fromList([0, 0, 0, 0])), 0.0);
    // target {0,1}, user {1,2}: inter=1, recall=1/2, precision=1/2 → F1=0.5
    final score = maskF1(
        Uint8List.fromList([1, 1, 0, 0]), Uint8List.fromList([0, 1, 1, 0]));
    expect(score, closeTo(0.5, 1e-9));
  });
}
