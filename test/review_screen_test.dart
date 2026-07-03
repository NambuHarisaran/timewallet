import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewallet/data/backend/data_backend.dart';
import 'package:timewallet/features/review/weekly_review_screen.dart';
import 'package:timewallet/state/app_providers.dart';

/// The review screen must render safely with no data (EmptyBackend) and show
/// the empty receipt rather than crashing. minuteTickProvider is periodic, so
/// pump with an explicit duration — never pumpAndSettle.
void main() {
  testWidgets('shows the empty receipt when there is no week data',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          backendProvider.overrideWithValue(const EmptyBackend()),
        ],
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: WeeklyReviewScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Nothing logged last week'), findsOneWidget);
  });
}
