import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewallet/data/backend/data_backend.dart';
import 'package:timewallet/features/goals/goals_screen.dart';
import 'package:timewallet/state/app_providers.dart';

/// Regression cover for Q1: the shared add-goal sheet must keep Create
/// disabled until both title and amount are valid, and close on create.
/// (The old goals_screen copy silently no-opped on invalid input.)
void main() {
  Future<void> pumpHost(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          // No Firebase in widget tests: the no-op backend accepts writes.
          backendProvider.overrideWithValue(const EmptyBackend()),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAddGoalSheet(context, ref),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FilledButton createButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create goal'));

  testWidgets('create is disabled until title AND amount are valid',
      (tester) async {
    await pumpHost(tester);

    expect(createButton(tester).onPressed, isNull,
        reason: 'empty form must not be submittable');

    await tester.enterText(find.widgetWithText(TextField, 'What for?'), 'Trip');
    await tester.pump();
    expect(createButton(tester).onPressed, isNull,
        reason: 'title alone is not enough');

    await tester.enterText(
        find.widgetWithText(TextField, 'Target amount'), '5000');
    await tester.pump();
    expect(createButton(tester).onPressed, isNotNull,
        reason: 'valid title + amount enables create');
  });

  testWidgets('creating a goal closes the sheet', (tester) async {
    await pumpHost(tester);

    await tester.enterText(find.widgetWithText(TextField, 'What for?'), 'Trip');
    await tester.enterText(
        find.widgetWithText(TextField, 'Target amount'), '5000');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Create goal'));
    await tester.pumpAndSettle();

    expect(find.text('Create goal'), findsNothing);
  });
}
