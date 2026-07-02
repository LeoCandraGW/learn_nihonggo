import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/seal_badge.dart';
import '../practice/drawing_canvas.dart';
import 'recognizer.dart';

/// Row picker: choose a gojūon line (あいうえお …) to drill. Re-runnable anytime.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.type});
  final String type;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late Future<(List<List<Character>>, Map<int, Progress>)> _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = AppRepository.instance;
    _data = Future.wait([
      repo.charactersOfType(widget.type),
      repo.progressForType(widget.type),
    ]).then((r) {
      final chars = r[0] as List<Character>;
      final progress = r[1] as Map<int, Progress>;
      // Group consecutive characters into their gojūon rows, order preserved.
      final rows = <List<Character>>[];
      for (final c in chars) {
        if (rows.isEmpty || rows.last.first.rowLabel != c.rowLabel) {
          rows.add([c]);
        } else {
          rows.last.add(c);
        }
      }
      return (rows, progress);
    });
  }

  Future<void> _drill(List<Character> row) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _RowDrill(type: widget.type, row: row)));
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Sumi.accent(widget.type);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Sumi.washi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Sumi.sumi,
        title: Text('Review · ${Sumi.label(widget.type)}'),
      ),
      body: FutureBuilder<(List<List<Character>>, Map<int, Progress>)>(
        future: _data,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (rows, progress) = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final row = rows[i];
              final done =
                  row.every((c) => (progress[c.id] ?? const Progress()).learned);
              return _RowTile(
                  row: row, done: done, accent: accent, onTap: () => _drill(row));
            },
          );
        },
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile(
      {required this.row,
      required this.done,
      required this.accent,
      required this.onTap});
  final List<Character> row;
  final bool done;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(row.map((c) => c.symbol).join('  '),
                    style: const TextStyle(fontSize: 24, height: 1)),
              ),
              if (done)
                const SealBadge(size: 20)
              else
                Icon(Icons.chevron_right, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drill one row: draw each glyph from its reading; the system checks the
/// drawing and only advances on a match.
class _RowDrill extends StatefulWidget {
  const _RowDrill({required this.type, required this.row});
  final String type;
  final List<Character> row;

  @override
  State<_RowDrill> createState() => _RowDrillState();
}

class _RowDrillState extends State<_RowDrill> {
  int _index = 0;
  bool _checking = false;
  bool _hint = false;
  double? _lastScore; // last failed attempt's score, for the hint bar
  DrawingController _canvas = DrawingController();

  int get _now => DateTime.now().millisecondsSinceEpoch;
  Character get _c => widget.row[_index];

  @override
  void dispose() {
    _canvas.dispose();
    super.dispose();
  }

  void _next() {
    _canvas.dispose();
    setState(() {
      _canvas = DrawingController();
      _checking = false;
      _lastScore = null;
      _hint = false;
      _index++;
    });
  }

  Future<void> _check() async {
    if (_canvas.isEmpty || _checking) return;
    setState(() => _checking = true);
    final score = await matchScore(_c.symbol, _canvas.current().strokes);
    if (!mounted) return;
    if (score >= passThreshold) {
      await AppRepository.instance.review(_c.id, correct: true, now: _now);
      if (!mounted) return;
      _next();
    } else {
      setState(() {
        _checking = false;
        _lastScore = score;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Sumi.accent(widget.type);
    final done = _index >= widget.row.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Sumi.washi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Sumi.sumi,
        title: Text(done ? 'Complete' : '${_index + 1} / ${widget.row.length}'),
      ),
      body: done ? _complete(accent) : _drill(accent),
    );
  }

  Widget _complete(Color accent) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SealBadge(size: 64),
              const SizedBox(height: 24),
              Text('Row complete',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('All matched from memory.',
                  style: TextStyle(color: Sumi.muted)),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14)),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );

  Widget _drill(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _index / widget.row.length,
            minHeight: 3,
            backgroundColor: Sumi.washiDeep,
            color: accent,
          ),
          const SizedBox(height: 20),
          Text('WRITE THIS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            _c.meaning == null ? _c.reading : '${_c.reading} · ${_c.meaning}',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: accent, fontSize: 34),
          ),
          const SizedBox(height: 16),
          DrawingCanvas(
            key: ValueKey(_index), // fresh canvas per letter
            accent: accent,
            guide: _hint ? _c.symbol : null,
            controller: _canvas,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 22,
            child: _lastScore == null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _hint = !_hint),
                      style: TextButton.styleFrom(foregroundColor: Sumi.muted),
                      icon: Icon(_hint ? Icons.visibility_off : Icons.visibility,
                          size: 16),
                      label: Text(_hint ? 'Hide hint' : 'Hint'),
                    ),
                  )
                : Text(
                    "Not quite (${(_lastScore! * 100).round()}%) — clear and try again",
                    style: const TextStyle(color: Sumi.shu, fontSize: 13),
                  ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _canvas.undo();
                    setState(() => _lastScore = null);
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Sumi.muted,
                      side: const BorderSide(color: Sumi.grid),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Undo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _canvas.clear();
                    setState(() => _lastScore = null);
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Sumi.muted,
                      side: const BorderSide(color: Sumi.grid),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _checking ? null : _check,
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
          ),
        ],
      ),
    );
  }
}
