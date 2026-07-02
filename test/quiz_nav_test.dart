import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_nihonggo/features/quiz/quiz_screen.dart';

void main() {
  testWidgets('quiz starts fresh (Q1, not result) on each open', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => const QuizScreen(type: 'hiragana'))),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));

    Future<void> open() async {
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
    }

    await open();
    expect(find.textContaining('WRITE IN'), findsOneWidget, reason: 'shows a question');
    expect(find.text('Done'), findsNothing, reason: 'not the result screen');

    await t.pageBack();
    await t.pumpAndSettle();

    await open();
    expect(find.textContaining('WRITE IN'), findsOneWidget);
    expect(find.text('Done'), findsNothing, reason: 'reopen must not be pre-marked done');
  });
}
