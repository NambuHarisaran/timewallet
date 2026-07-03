import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewallet/data/backend/data_backend.dart';
import 'package:timewallet/features/review/review_hub_screen.dart';
import 'package:timewallet/state/app_providers.dart';

/// The Review tab groups the weekly ritual with the deeper look-backs.
void main() {
  testWidgets('lists the weekly review and the look-back destinations',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          backendProvider.overrideWithValue(const EmptyBackend()),
        ],
        child: const MaterialApp(home: ReviewHubScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('This week in hours'), findsOneWidget);
    expect(find.text('Wrapped'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
  });
}
