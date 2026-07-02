import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../chart/chart_screen.dart';
import '../review/review_screen.dart';

const _scripts = [
  ('hiragana', 'あ', 'Hiragana', 'the everyday syllabary'),
  ('katakana', 'ア', 'Katakana', 'for foreign words'),
  ('kanji', '一', 'Kanji', 'meaning in a stroke'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, double>> _mastery;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = AppRepository.instance;
    _mastery = Future.wait(_scripts.map((s) => repo.masteryOfType(s.$1)))
        .then((values) => {
              for (var i = 0; i < _scripts.length; i++) _scripts[i].$1: values[i]
            });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    setState(_load); // refresh progress on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, double>>(
          future: _mastery,
          builder: (context, snap) {
            final mastery = snap.data ?? const {};
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              children: [
                Text('日本語',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontSize: 72, color: Sumi.sumi)),
                const SizedBox(height: 4),
                Text('LEARN JAPANESE BY HAND',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 32),
                for (final s in _scripts)
                  _ScriptCard(
                    type: s.$1,
                    sample: s.$2,
                    title: s.$3,
                    subtitle: s.$4,
                    mastery: mastery[s.$1] ?? 0,
                    onChart: () => _open(ChartScreen(type: s.$1)),
                    onReview: () => _open(ReviewScreen(type: s.$1)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScriptCard extends StatelessWidget {
  const _ScriptCard({
    required this.type,
    required this.sample,
    required this.title,
    required this.subtitle,
    required this.mastery,
    required this.onChart,
    required this.onReview,
  });

  final String type, sample, title, subtitle;
  final double mastery;
  final VoidCallback onChart, onReview;

  @override
  Widget build(BuildContext context) {
    final accent = Sumi.accent(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onChart,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border(left: BorderSide(color: accent, width: 4)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sample,
                        style: TextStyle(
                            fontSize: 56, height: 1, color: accent)),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(Sumi.label(type),
                              style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 4,
                                  color: accent,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(title,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          Text(subtitle,
                              style: const TextStyle(
                                  color: Sumi.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('${(mastery * 100).round()}%',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: mastery >= 1 ? accent : Sumi.muted)),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: mastery,
                    minHeight: 4,
                    backgroundColor: Sumi.washiDeep,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onReview,
                    style: TextButton.styleFrom(foregroundColor: accent),
                    child: const Text('Review  →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
