import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../chart/chart_screen.dart';
import '../quiz/quiz_screen.dart';
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

typedef _Stats = ({
  Map<String, double> mastery,
  Map<String, int> due,
  int streak,
});

class _HomeScreenState extends State<HomeScreen> {
  late Future<_Stats> _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = AppRepository.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    _stats = () async {
      final mastery = <String, double>{};
      final due = <String, int>{};
      for (final s in _scripts) {
        mastery[s.$1] = await repo.masteryOfType(s.$1);
        due[s.$1] = await repo.dueCount(s.$1, now: now);
      }
      final streak = await repo.currentStreak(now: now);
      return (mastery: mastery, due: due, streak: streak);
    }();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    setState(_load); // refresh progress on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_Stats>(
          future: _stats,
          builder: (context, snap) {
            final mastery = snap.data?.mastery ?? const {};
            final due = snap.data?.due ?? const {};
            final streak = snap.data?.streak ?? 0;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('日本語',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontSize: 72, color: Sumi.sumi)),
                    ),
                    if (streak > 0) _StreakChip(streak: streak),
                  ],
                ),
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
                    due: due[s.$1] ?? 0,
                    onChart: () => _open(ChartScreen(type: s.$1)),
                    onReview: () => _open(ReviewScreen(type: s.$1)),
                    onQuiz: () => _open(QuizScreen(type: s.$1)),
                    onAdvanced: () =>
                        _open(QuizScreen(type: s.$1, advanced: true)),
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
    required this.due,
    required this.onChart,
    required this.onReview,
    required this.onQuiz,
    required this.onAdvanced,
  });

  final String type, sample, title, subtitle;
  final double mastery;
  final int due;
  final VoidCallback onChart, onReview, onQuiz, onAdvanced;

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(mastery * 100).round()}%',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: mastery >= 1 ? accent : Sumi.muted)),
                        if (due > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$due due',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: onQuiz,
                      style: TextButton.styleFrom(foregroundColor: Sumi.muted),
                      icon: const Icon(Icons.quiz_outlined, size: 18),
                      label: const Text('Quiz'),
                    ),
                    TextButton.icon(
                      onPressed: onAdvanced,
                      style: TextButton.styleFrom(foregroundColor: Sumi.muted),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Advanced'),
                    ),
                    TextButton(
                      onPressed: onReview,
                      style: TextButton.styleFrom(foregroundColor: accent),
                      child: const Text('Review  →'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Daily study streak — the habit nudge. Hidden at zero.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Sumi.shu.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text('$streak',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Sumi.shu)),
          const SizedBox(width: 4),
          Text(streak == 1 ? 'day' : 'days',
              style: const TextStyle(fontSize: 12, color: Sumi.muted)),
        ],
      ),
    );
  }
}
