import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/features/tools/guided_tool_flow.dart';

/// The guided tool flow: one question per screen, output-only result page,
/// answers editable via chips.
void main() {
  Widget flow() => MaterialApp(
        home: GuidedToolFlow(
          title: 'Demo tool',
          questions: const [
            ToolQuestion(
              question: 'First question?',
              label: 'One',
              answer: 'A1',
              input: Text('input-1'),
            ),
            ToolQuestion(
              question: 'Second question?',
              label: 'Two',
              answer: 'A2',
              input: Text('input-2'),
            ),
          ],
          results: const [Text('THE RESULT')],
        ),
      );

  testWidgets('walks the questions, then shows only the output',
      (tester) async {
    await tester.pumpWidget(flow());

    expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
    expect(find.text('First question?'), findsOneWidget);
    expect(find.text('THE RESULT'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Second question?'), findsOneWidget);

    await tester.tap(find.text('See my result'));
    await tester.pumpAndSettle();
    expect(find.text('THE RESULT'), findsOneWidget);
    expect(find.text('First question?'), findsNothing);
    // Answer chips summarise every input.
    expect(find.text('One · A1'), findsOneWidget);
    expect(find.text('Two · A2'), findsOneWidget);
  });

  testWidgets('result chip jumps to one question and returns on update',
      (tester) async {
    await tester.pumpWidget(flow());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See my result'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('One · A1'));
    await tester.pumpAndSettle();
    expect(find.text('First question?'), findsOneWidget);
    expect(find.text('Update result'), findsOneWidget);

    await tester.tap(find.text('Update result'));
    await tester.pumpAndSettle();
    expect(find.text('THE RESULT'), findsOneWidget);
  });

  testWidgets('start over returns to the first question', (tester) async {
    await tester.pumpWidget(flow());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See my result'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();
    expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
  });
}
