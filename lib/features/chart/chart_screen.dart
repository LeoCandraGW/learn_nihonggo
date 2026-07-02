import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/seal_badge.dart';
import '../practice/character_screen.dart';

/// The gojūon table — every character of one script, tap to practice.
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key, required this.type});
  final String type;

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late Future<(List<Character>, Map<int, Progress>)> _data;

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
    ]).then((r) =>
        (r[0] as List<Character>, r[1] as Map<int, Progress>));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Sumi.accent(widget.type);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Sumi.washi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Sumi.sumi,
        title: Text('${Sumi.label(widget.type)}  ·  ${widget.type}'),
      ),
      body: FutureBuilder<(List<Character>, Map<int, Progress>)>(
        future: _data,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (chars, progress) = snap.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: chars.length,
            itemBuilder: (context, i) {
              final c = chars[i];
              final p = progress[c.id] ?? const Progress();
              return _KanaTile(
                character: c,
                progress: p,
                accent: accent,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CharacterScreen(character: c)));
                  setState(_load);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _KanaTile extends StatelessWidget {
  const _KanaTile({
    required this.character,
    required this.progress,
    required this.accent,
    required this.onTap,
  });

  final Character character;
  final Progress progress;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Box level tints the tile — visible learning heat.
    final heat = progress.box / 4;
    return Material(
      color: Color.lerp(Colors.white, accent.withValues(alpha: 0.14), heat),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(character.symbol,
                      style: const TextStyle(fontSize: 30, height: 1.1)),
                  Text(character.reading,
                      style: const TextStyle(
                          fontSize: 11, color: Sumi.muted, height: 1.4)),
                ],
              ),
            ),
            if (progress.learned)
              const Positioned(top: 4, right: 4, child: SealBadge(size: 18)),
          ],
        ),
      ),
    );
  }
}
