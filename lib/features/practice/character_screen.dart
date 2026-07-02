import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import 'drawing_canvas.dart';

/// Detail + handwriting practice for one character. Free drilling only —
/// mastery is earned in Review, not declared here.
class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key, required this.character});
  final Character character;

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  final _canvas = DrawingController();
  bool _trace = true; // show faint guide + reference glyph; off = memory mode

  Character get c => widget.character;

  @override
  void dispose() {
    _canvas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Sumi.accent(c.type);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Sumi.washi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Sumi.sumi,
        title: Text(c.reading),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Reference glyph — hidden in memory mode so you recall it yourself.
          Center(
            child: _trace
                ? Text(c.symbol,
                    style:
                        TextStyle(fontSize: 120, height: 1.1, color: accent))
                : const SizedBox(
                    height: 132,
                    child: Center(
                      child: Text('？',
                          style: TextStyle(fontSize: 96, color: Sumi.grid)),
                    ),
                  ),
          ),
          Center(
            child: Text(
              c.meaning == null ? c.reading : '${c.reading} · ${c.meaning}',
              style: const TextStyle(fontSize: 16, color: Sumi.muted),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRACTICE', style: Theme.of(context).textTheme.labelSmall),
              Row(
                children: [
                  const Text('Trace', style: TextStyle(color: Sumi.muted)),
                  Switch(
                    value: _trace,
                    activeThumbColor: accent,
                    onChanged: (v) => setState(() => _trace = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          DrawingCanvas(
            accent: accent,
            guide: _trace ? c.symbol : null,
            controller: _canvas,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CanvasButton(
                    icon: Icons.undo, label: 'Undo', onTap: _canvas.undo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CanvasButton(
                    icon: Icons.clear, label: 'Clear', onTap: _canvas.clear),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CanvasButton extends StatelessWidget {
  const _CanvasButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          foregroundColor: Sumi.muted,
          side: const BorderSide(color: Sumi.grid),
          padding: const EdgeInsets.symmetric(vertical: 14)),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
