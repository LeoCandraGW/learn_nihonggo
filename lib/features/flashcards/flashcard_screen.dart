import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mnemonics.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/seal_badge.dart';

/// Recognition recall: see the glyph, recall its sound, flip to check, then
/// self-grade. Complements Review (which tests writing). Feeds the same
/// Leitner boxes via AppRepository.review.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, required this.type});
  final String type;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  static const _sessionSize = 20;

  late Future<List<Character>> _cards;
  int _index = 0;
  bool _flipped = false;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _cards = AppRepository.instance.charactersOfType(widget.type).then((all) {
      final list = [...all]..shuffle(Random());
      return list.take(_sessionSize).toList();
    });
  }

  Future<void> _grade(int id, bool correct) async {
    await AppRepository.instance.review(id, correct: correct, now: _now);
    if (!mounted) return;
    setState(() {
      _flipped = false;
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
        title: Text('Flashcards · ${Sumi.label(widget.type)}'),
      ),
      body: FutureBuilder<List<Character>>(
        future: _cards,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cards = snap.data!;
          if (cards.isEmpty) {
            return const Center(
                child: Text('Nothing to study yet.',
                    style: TextStyle(color: Sumi.muted)));
          }
          if (_index >= cards.length) return _done(accent, cards.length);
          return _card(accent, cards[_index], cards.length);
        },
      ),
    );
  }

  Widget _done(Color accent, int total) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SealBadge(size: 64),
            const SizedBox(height: 24),
            Text('$total reviewed',
                style: Theme.of(context).textTheme.headlineMedium),
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
      );

  Widget _card(Color accent, Character c, int total) {
    final mnemonic = kMnemonics[c.symbol];
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
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = true),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Sumi.grid),
                ),
                child: Center(
                  child: !_flipped
                      // Front: the glyph. Recall its sound.
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.symbol,
                                style: TextStyle(
                                    fontSize: 140, height: 1, color: accent)),
                            const SizedBox(height: 16),
                            const Text('tap to flip',
                                style:
                                    TextStyle(color: Sumi.muted, fontSize: 13)),
                          ],
                        )
                      // Back: the answer.
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c.reading,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(fontSize: 48, color: accent)),
                              if (c.meaning != null) ...[
                                const SizedBox(height: 8),
                                Text(c.meaning!,
                                    style: const TextStyle(
                                        fontSize: 18, color: Sumi.muted)),
                              ],
                              if (mnemonic != null) ...[
                                const SizedBox(height: 20),
                                Text(mnemonic,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: Sumi.sumi)),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (!_flipped)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(() => _flipped = true),
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
                    onPressed: () => _grade(c.id, false),
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
                    onPressed: () => _grade(c.id, true),
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
  }
}
