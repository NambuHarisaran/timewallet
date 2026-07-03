import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewallet/data/backend/data_backend.dart';
import 'package:timewallet/features/expense/add_expense_screen.dart';
import 'package:timewallet/state/app_providers.dart';

/// X2 — the redesigned capture form: mood is gone from the form, the note lives
/// under "More options", and category selection drives the need/want default.
void main() {
  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          backendProvider.overrideWithValue(const EmptyBackend()),
        ],
        child: const MaterialApp(home: AddExpenseScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('mood chips are no longer on the form', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.sentiment_neutral), findsNothing);
    expect(find.byIcon(Icons.sentiment_satisfied_alt), findsNothing);
    expect(find.text('How do you feel?'), findsNothing);
  });

  testWidgets('note field is hidden until "More options" is expanded',
      (tester) async {
    await pump(tester);
    expect(find.widgetWithText(TextField, 'Note (optional)'), findsNothing);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Note (optional)'), findsOneWidget);
  });

  testWidgets('choosing a want category flips the need/want chip',
      (tester) async {
    await pump(tester);
    // Food (default) → Need.
    expect(find.textContaining('Need · tap to change'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Shopping'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Want · tap to change'), findsOneWidget);
  });
}
