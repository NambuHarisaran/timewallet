import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/widgets/value_field.dart';

/// ValueField — the manual-entry control that replaced the tool sliders.
void main() {
  Widget host(ValueChanged<double> onChanged, {double value = 5000}) {
    return MaterialApp(
      home: Scaffold(
        body: ValueField(
          label: 'Monthly investment',
          value: value,
          min: 100,
          max: 10000000,
          prefix: '₹ ',
          presets: const [1000, 25000],
          onChanged: onChanged,
        ),
      ),
    );
  }

  testWidgets('typing a valid number commits it', (tester) async {
    double? committed;
    await tester.pumpWidget(host((v) => committed = v));

    await tester.enterText(find.byType(TextField), '75000');
    expect(committed, 75000);
  });

  testWidgets('out-of-range input shows error and does not commit',
      (tester) async {
    double? committed;
    await tester.pumpWidget(host((v) => committed = v));

    await tester.enterText(find.byType(TextField), '50');
    await tester.pump();
    expect(committed, isNull);
    expect(find.textContaining('Enter'), findsOneWidget);
  });

  testWidgets('preset chip commits its value', (tester) async {
    double? committed;
    await tester.pumpWidget(host((v) => committed = v));

    await tester.tap(find.text('₹25,000'));
    await tester.pump();
    expect(committed, 25000);
  });

  testWidgets('invalid text is restored to the last value on blur',
      (tester) async {
    double? committed;
    await tester.pumpWidget(host((v) => committed = v));

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    // Move focus away — the field restores the committed value.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(committed, isNull);
    expect(find.text('5000'), findsOneWidget);
  });
}
