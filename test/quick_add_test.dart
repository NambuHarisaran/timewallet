import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewallet/data/backend/data_backend.dart';
import 'package:timewallet/features/expense/quick_add_sheet.dart';
import 'package:timewallet/state/app_providers.dart';

/// X2 — quick-add sheet: Save gated on amount; a want category surfaces Hold.
void main() {
  Future<void> pumpHost(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          backendProvider.overrideWithValue(const EmptyBackend()),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showQuickAddSheet(context, ref),
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

  testWidgets('Save is disabled until an amount is entered', (tester) async {
    await pumpHost(tester);
    final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'));
    expect(save.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '250');
    await tester.pump();
    final save2 = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'));
    expect(save2.onPressed, isNotNull);
  });

  testWidgets('picking a want category reveals the 24h Hold action',
      (tester) async {
    await pumpHost(tester);
    await tester.enterText(find.byType(TextField).first, '999');
    await tester.pump();

    // Default category (food) is a need → no Hold button.
    expect(find.textContaining('Hold 24h'), findsNothing);

    // Shopping (a want) sits near the start of the horizontal row.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Shopping'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hold 24h'), findsOneWidget);
  });
}
