import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../practice/drawing_canvas.dart';

/// Spaced-repetition session: recall the glyph from its reading, draw it from
/// memory, reveal, then self-grade. Grading feeds the Leitner scheduler.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.type});
  final String type;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late Future<List<Character>> _queue;
  final List<Character> _cards = [];
  int _index = 0;
  bool _revealed = false;
  DrawingController _canvas = DrawingController();

  int get _now => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _queue = AppRepository.instance
        .dueForReview(widget.type, now: _now)
        .then((c) => _cards..addAll(c));
  }

  @override
  void dispose() {
    _canvas.dispose();
    super.dispose();
  }

  Future<void> _grade(bool correct) async {
    await AppRepository.instance
        .review(_cards[_index].id, correct: correct, now: _now);
    _canvas.dispose();
    setState(() {
      _canvas = DrawingController();
      _revealed = false;
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
        title: const Text('Review'),
      ),
      body: FutureBuilder<List<Character>>(
        future: _queue,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_cards.isEmpty) {
            return const _Empty(text: 'Nothing due. Come back later — 🌱');
          }
          if (_index >= _cards.length) {
            return _Empty(text: 'Session complete — ${_cards.length} reviewed 🎉');
          }
          final c = _cards[_index];
          final prompt = c.meaning == null ? c.reading : '${c.reading} · ${c.meaning}';
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _index / _cards.length,
                  minHeight: 3,
                  backgroundColor: Sumi.washiDeep,
                  color: accent,
                ),
                const SizedBox(height: 24),
                Text('WRITE THIS FROM MEMORY',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                Text(prompt,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: accent)),
                const SizedBox(height: 20),
                // Reveal replaces the blank canvas with the answer glyph.
                Expanded(
                  child: Center(
                    child: _revealed
                        ? Text(c.symbol,
                            style: TextStyle(
                                fontSize: 160, height: 1, color: accent))
                        : DrawingCanvas(accent: accent, controller: _canvas),
                  ),
                ),
                const SizedBox(height: 20),
                if (!_revealed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => setState(() => _revealed = true),
                      style: FilledButton.styleFrom(
                          backgroundColor: Sumi.sumi,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Reveal'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _grade(false),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Sumi.muted,
                              side: const BorderSide(color: Sumi.grid),
                              padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Again'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _grade(true),
                          style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Got it'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Sumi.muted)),
        ),
      );
}
