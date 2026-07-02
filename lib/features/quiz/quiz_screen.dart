import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/seal_badge.dart';
import '../practice/drawing_canvas.dart';
import '../review/recognizer.dart';

/// One quiz prompt: write [answer] (kana word or kanji) given [prompt].
class QuizItem {
  const QuizItem(this.prompt, this.answer);
  final String prompt; // "aka (red)" or "water"
  final String answer; // あか / 水
}

/// Word-writing quizzes from the MLC Hiragana/Katakana worksheet.
const _hiragana = <QuizItem>[
  QuizItem('aka (red)', 'あか'), QuizItem('ao (blue)', 'あお'),
  QuizItem('aki (autumn)', 'あき'), QuizItem('eki (station)', 'えき'),
  QuizItem('ie (house)', 'いえ'), QuizItem('ue (on top)', 'うえ'),
  QuizItem('asa (morning)', 'あさ'), QuizItem('shio (salt)', 'しお'),
  QuizItem('kutsu (shoes)', 'くつ'), QuizItem('neko (cat)', 'ねこ'),
  QuizItem('nani (what)', 'なに'), QuizItem('inu (dog)', 'いぬ'),
  QuizItem('niku (meat)', 'にく'), QuizItem('fune (ship)', 'ふね'),
  QuizItem('hoshi (star)', 'ほし'), QuizItem('hito (person)', 'ひと'),
  QuizItem('hako (box)', 'はこ'), QuizItem('ame (rain)', 'あめ'),
  QuizItem('mushi (insect)', 'むし'), QuizItem('yuki (snow)', 'ゆき'),
  QuizItem('fuyu (winter)', 'ふゆ'), QuizItem('kore (this)', 'これ'),
  QuizItem('sore (that)', 'それ'), QuizItem('hon (book)', 'ほん'),
  QuizItem('kuro (black)', 'くろ'), QuizItem('namae (name)', 'なまえ'),
  QuizItem('kuruma (car)', 'くるま'), QuizItem('watashi (I)', 'わたし'),
];

const _katakana = <QuizItem>[
  QuizItem('basu (bus)', 'バス'), QuizItem('gasu (gas)', 'ガス'),
  QuizItem('hamu (ham)', 'ハム'), QuizItem('memo (memo)', 'メモ'),
  QuizItem('gamu (gum)', 'ガム'), QuizItem('tsuna (tuna)', 'ツナ'),
  QuizItem('yuza (user)', 'ユーザ'), QuizItem('tenisu (tennis)', 'テニス'),
  QuizItem('tomato (tomato)', 'トマト'), QuizItem('wain (wine)', 'ワイン'),
  QuizItem('taoru (towel)', 'タオル'), QuizItem('noto (notebook)', 'ノート'),
  QuizItem('keki (cake)', 'ケーキ'), QuizItem('toire (toilet)', 'トイレ'),
  QuizItem('ruru (rule)', 'ルール'), QuizItem('sakka (soccer)', 'サッカー'),
];

/// Advanced: real words & phrases. Prompt is the English meaning.
const _advHiragana = <QuizItem>[
  QuizItem('good morning', 'おはよう'), QuizItem('hello', 'こんにちは'),
  QuizItem('good evening', 'こんばんは'), QuizItem('good night', 'おやすみ'),
  QuizItem('thank you', 'ありがとう'), QuizItem('goodbye', 'さようなら'),
  QuizItem('excuse me / sorry', 'すみません'), QuizItem('how are you?', 'げんきですか'),
  QuizItem('nice to meet you', 'はじめまして'), QuizItem("I'm sorry", 'ごめんなさい'),
  QuizItem('yes', 'はい'), QuizItem('no', 'いいえ'),
  QuizItem('delicious', 'おいしい'), QuizItem('cute', 'かわいい'),
  QuizItem('see you', 'じゃあね'),
];

const _advKatakana = <QuizItem>[
  QuizItem('coffee', 'コーヒー'), QuizItem('television', 'テレビ'),
  QuizItem('camera', 'カメラ'), QuizItem('hotel', 'ホテル'),
  QuizItem('restaurant', 'レストラン'), QuizItem('ice cream', 'アイスクリーム'),
  QuizItem('hamburger', 'ハンバーガー'), QuizItem('chocolate', 'チョコレート'),
  QuizItem('elevator', 'エレベーター'), QuizItem('table', 'テーブル'),
  QuizItem('juice', 'ジュース'), QuizItem('pen', 'ペン'),
  QuizItem('supermarket', 'スーパー'), QuizItem('necktie', 'ネクタイ'),
];

const _advKanji = <QuizItem>[
  QuizItem('Japan', '日本'), QuizItem('student', '学生'),
  QuizItem('teacher', '先生'), QuizItem('today', '今日'),
  QuizItem('every day', '毎日'), QuizItem('university', '大学'),
  QuizItem('school', '学校'), QuizItem('company', '会社'),
  QuizItem('train', '電車'), QuizItem('name', '名前'),
  QuizItem('this week', '今週'), QuizItem('next year', '来年'),
  QuizItem('what time', '何時'), QuizItem('China', '中国'),
  QuizItem('one person', '一人'),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.type, this.advanced = false});
  final String type;

  /// Advanced = write real words & phrases from their English meaning.
  final bool advanced;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _sessionSize = 10;

  late Future<List<QuizItem>> _items;
  int _index = 0;
  int _correct = 0;
  bool _checking = false;
  double? _score; // word score after Check → shows result panel

  // One character per canvas. _ink holds each character's strokes; _cell is the
  // character currently being drawn; _cellScores holds per-character results.
  int _cell = 0;
  List<DrawingData> _ink = [];
  List<double>? _cellScores;
  DrawingController _canvas = DrawingController();

  @override
  void initState() {
    super.initState();
    _items = _buildSession();
  }

  Future<List<QuizItem>> _buildSession() async {
    List<QuizItem> pool;
    if (widget.advanced) {
      pool = switch (widget.type) {
        'hiragana' => [..._advHiragana],
        'katakana' => [..._advKatakana],
        _ => [..._advKanji],
      };
    } else {
      switch (widget.type) {
        case 'hiragana':
          pool = [..._hiragana];
        case 'katakana':
          pool = [..._katakana];
        default: // kanji: write the character from its meaning
          final chars = await AppRepository.instance.charactersOfType('kanji');
          pool = [for (final c in chars) QuizItem(c.meaning ?? c.reading, c.symbol)];
      }
    }
    pool.shuffle(Random());
    return pool.take(_sessionSize).toList();
  }

  @override
  void dispose() {
    _canvas.dispose();
    super.dispose();
  }

  /// Persist the character currently on the canvas into [_ink].
  void _saveCurrent() => _ink[_cell] = _canvas.current();

  void _switchCell(int i) {
    if (i == _cell) return;
    _saveCurrent();
    setState(() => _cell = i);
  }

  Future<void> _check(QuizItem item) async {
    if (_checking) return;
    _saveCurrent();
    setState(() => _checking = true);
    final scores = <double>[];
    for (var i = 0; i < item.answer.length; i++) {
      scores.add(await matchScore(item.answer[i], _ink[i].strokes));
    }
    if (!mounted) return;
    final word = scores.reduce(min); // the word is only as good as its weakest character
    setState(() {
      _checking = false;
      _cellScores = scores;
      _score = word;
      if (word >= passThreshold) _correct++;
    });
  }

  void _next() {
    _canvas.dispose();
    setState(() {
      _canvas = DrawingController();
      _ink = [];
      _cell = 0;
      _score = null;
      _cellScores = null;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Sumi.accent(widget.type);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Sumi.washi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Sumi.sumi,
        title: Text(
            '${widget.advanced ? 'Advanced' : 'Quiz'} · ${Sumi.label(widget.type)}'),
      ),
      body: FutureBuilder<List<QuizItem>>(
        future: _items,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (_index >= items.length) return _result(accent, items.length);
          return _question(accent, items[_index], items.length);
        },
      ),
    );
  }

  Widget _result(Color accent, int total) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SealBadge(size: 64),
              const SizedBox(height: 24),
              Text('$_correct / $total',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(fontSize: 64, color: accent)),
              const SizedBox(height: 8),
              const Text('correct', style: TextStyle(color: Sumi.muted)),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );

  Widget _question(Color accent, QuizItem item, int total) {
    final n = item.answer.length;
    // Lazy-init this question's per-character ink (also runs after _next clears it).
    if (_ink.length != n) {
      _ink = List.generate(n, (_) => const DrawingData(<List<Offset>>[]));
      _cell = 0;
    }
    final graded = _score != null;
    final passed = graded && _score! >= passThreshold;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _index / total,
            minHeight: 3,
            backgroundColor: Sumi.washiDeep,
            color: accent,
          ),
          const SizedBox(height: 20),
          Text('WRITE IN ${Sumi.label(widget.type)}',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Text(item.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: accent)),
          const SizedBox(height: 16),
          // Tap a box to draw that character. Only shown for multi-char words.
          if (n > 1)
            _CellStrip(
              count: n,
              current: _cell,
              answer: item.answer,
              scores: _cellScores,
              accent: accent,
              onTap: _switchCell,
            ),
          if (n > 1) const SizedBox(height: 12),
          // Full-size canvas for the selected character.
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DrawingCanvas(
                  key: ValueKey('$_index-$_cell'),
                  accent: accent,
                  controller: _canvas,
                  initial: _ink[_cell],
                  guide: graded ? item.answer[_cell] : null,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: graded
                ? Center(
                    child: Text(
                      passed
                          ? '✓ Correct'
                          : 'Answer: ${item.answer}  (${(_score! * 100).round()}%)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: passed ? accent : Sumi.shu),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (!graded)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canvas.undo,
                    style: _outlined,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canvas.clear,
                    style: _outlined,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _checking ? null : () => _check(item),
                    style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _checking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Check'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                    backgroundColor: Sumi.sumi,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(_index + 1 >= total ? 'See score' : 'Next'),
              ),
            ),
        ],
      ),
    );
  }

  ButtonStyle get _outlined => OutlinedButton.styleFrom(
      foregroundColor: Sumi.muted,
      side: const BorderSide(color: Sumi.grid),
      padding: const EdgeInsets.symmetric(vertical: 16));
}

/// A row of boxes, one per character. Tap to draw that character. Before
/// grading it shows the position number; after, the answer glyph tinted by
/// whether that character was matched.
class _CellStrip extends StatelessWidget {
  const _CellStrip({
    required this.count,
    required this.current,
    required this.answer,
    required this.scores,
    required this.accent,
    required this.onTap,
  });

  final int count;
  final int current;
  final String answer;
  final List<double>? scores;
  final Color accent;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < count; i++) _box(i),
      ],
    );
  }

  Widget _box(int i) {
    final graded = scores != null;
    final ok = graded && scores![i] >= passThreshold;
    final isCurrent = i == current;
    final tint = graded ? (ok ? accent : Sumi.shu) : accent;
    return GestureDetector(
      onTap: () => onTap(i),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCurrent ? tint.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? tint : Sumi.grid,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Text(
          graded ? answer[i] : '${i + 1}',
          style: TextStyle(
            fontSize: graded ? 22 : 14,
            fontWeight: FontWeight.w600,
            color: graded ? tint : Sumi.muted,
          ),
        ),
      ),
    );
  }
}
