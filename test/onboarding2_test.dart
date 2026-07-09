import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewallet/data/backend/data_backend.dart';
import 'package:timewallet/data/models/user_profile.dart';
import 'package:timewallet/features/intro/intro_flow_screen.dart';
import 'package:timewallet/features/onboarding/onboarding_screen.dart';
import 'package:timewallet/state/app_providers.dart';
import 'package:timewallet/widgets/step_progress_bar.dart';
import 'package:timewallet/widgets/time_card.dart';

/// Onboarding 2.0 coverage: the intro→onboarding prefill hand-off (smart
/// defaults), the goal-gradient progress bar, and the IKEA-effect Time Card
/// (cardStyle persistence + the card widget itself).
void main() {
  group('UserProfile.cardStyle', () {
    test('survives a json roundtrip', () {
      const p = UserProfile(cardStyle: 3);
      expect(UserProfile.fromJson(p.toJson()).cardStyle, 3);
    });

    test('defaults to 0 when absent or malformed', () {
      expect(UserProfile.fromJson(const {}).cardStyle, 0);
      expect(UserProfile.fromJson(const {'cardStyle': 'junk'}).cardStyle, 0);
    });

    test('copyWith preserves it when untouched', () {
      const p = UserProfile(cardStyle: 2);
      expect(p.copyWith(name: 'Asha').cardStyle, 2);
    });
  });

  group('StepProgressBar', () {
    Future<void> pump(WidgetTester tester, double value) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StepProgressBar(value: value, label: 'Step 1 of 3'),
            ),
          ),
        );

    testWidgets('shows label and settles on the given percent',
        (tester) async {
      await pump(tester, 0.25);
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('animates to a new value on rebuild', (tester) async {
      await pump(tester, 0.25);
      await tester.pumpAndSettle();
      await pump(tester, 0.5);
      await tester.pumpAndSettle();
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('TimeCard', () {
    // 86600 / (5 * 4.33 * 8) ≈ ₹500/hour — a tracksTime profile.
    const profile = UserProfile(
      name: 'Asha',
      persona: Persona.employee,
      incomeType: IncomeType.fixed,
      monthlyIncome: 86600,
    );

    testWidgets('renders embossed owner name and hourly worth',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TimeCard(profile: profile))),
      );
      expect(find.text('ASHA'), findsOneWidget);
      expect(find.text('MY TIME IS WORTH'), findsOneWidget);
      expect(find.textContaining('/ hour'), findsOneWidget);
    });

    testWidgets('style picker reports the tapped swatch', (tester) async {
      int? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeCardStylePicker(
              selected: 0,
              onSelected: (i) => picked = i,
            ),
          ),
        ),
      );
      final swatches = find.byType(GestureDetector);
      await tester.tap(swatches.at(2));
      expect(picked, 2);
    });
  });

  group('Onboarding prefill (smart defaults from intro)', () {
    Future<void> pumpOnboarding(WidgetTester tester,
        {Map<String, Object> prefsSeed = const {}}) async {
      SharedPreferences.setMockInitialValues(prefsSeed);
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            backendProvider.overrideWithValue(const EmptyBackend()),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('income + persona from the intro arrive pre-answered',
        (tester) async {
      await pumpOnboarding(tester, prefsSeed: {
        'intro_income': 60000.0,
        'intro_persona': Persona.student.index,
      });

      // Income seeded and named as such — silent prefills read as spooky.
      // skipOffstage: the test font (Ahem) is wide enough to push the field
      // below the fold, where it's built into the cache but offstage.
      final incomeField = tester.widget<TextField>(
          find.byType(TextField, skipOffstage: false).first);
      expect(incomeField.controller!.text, '60000');
      expect(
          find.textContaining('Prefilled from your earlier answer',
              skipOffstage: false),
          findsOneWidget);

      // Student persona infers the pocket-money income source.
      // skipOffstage: same Ahem-width reason as the income field above — the
      // chip is built but below the fold in the test font.
      final pocketChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Pocket money', skipOffstage: false));
      expect(pocketChip.selected, isTrue);

      // Advance to the about-you step: the persona chip is pre-picked.
      await tester.tap(find.widgetWithText(FilledButton, 'Next Step'));
      await tester.pumpAndSettle();
      final studentChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Student', skipOffstage: false));
      expect(studentChip.selected, isTrue);
    });

    testWidgets('no intro answers -> classic empty defaults', (tester) async {
      await pumpOnboarding(tester);
      expect(
          find.textContaining('Prefilled from your earlier answer',
              skipOffstage: false),
          findsNothing);
      final salaryChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Salary', skipOffstage: false));
      expect(salaryChip.selected, isTrue,
          reason: 'fixed salary stays the untouched default');
    });
  });

  group('Intro flow', () {
    Future<void> pumpIntro(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            backendProvider.overrideWithValue(const EmptyBackend()),
          ],
          child: const MaterialApp(home: IntroFlowScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    FilledButton cta(WidgetTester tester, String label) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

    testWidgets('quiz page gates Continue until the user plays a round',
        (tester) async {
      await pumpIntro(tester);
      expect(find.text('Your money is time.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(cta(tester, 'Continue').onPressed, isNull,
          reason: 'the guess IS the effort investment — no skipping it');

      // Guess the gadget (wrong — no confetti overlay to settle). The wide
      // test font pushes the option cards below the fold — scroll to them.
      final gadget = find.textContaining('gadget', skipOffstage: false).first;
      await tester.ensureVisible(gadget);
      await tester.pumpAndSettle();
      await tester.tap(gadget);
      await tester.pumpAndSettle();
      expect(cta(tester, 'Continue').onPressed, isNotNull);
      expect(find.textContaining('Sneaky, right?', skipOffstage: false),
          findsOneWidget);
    });
  });

  // End-to-end navigation: proves each flow advances through every page and
  // lands on the expected content. Pumped at the default test surface — the
  // test font (Ahem) renders ~1em per glyph and trips false overflows on a
  // shrunk viewport that the whole suite avoids; every Row in these screens
  // is Expanded/Flexible-guarded by construction, so real fonts have ample
  // room on any phone.
  group('Flow navigation', () {
    Future<void> pump(WidgetTester tester, Widget home,
        {Map<String, Object> prefsSeed = const {}}) async {
      SharedPreferences.setMockInitialValues(prefsSeed);
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            backendProvider.overrideWithValue(const EmptyBackend()),
          ],
          child: MaterialApp(home: home),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('intro flow advances through all three pages', (tester) async {
      await pump(tester, const IntroFlowScreen());
      expect(find.text('Your money is time.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Small leaks sink ships.'), findsOneWidget);

      final gadget = find.textContaining('gadget', skipOffstage: false).first;
      await tester.ensureVisible(gadget);
      await tester.pumpAndSettle();
      await tester.tap(gadget);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Who are you?'), findsOneWidget);
    });

    testWidgets('onboarding advances to the Time Card step', (tester) async {
      await pump(tester, const OnboardingScreen(), prefsSeed: {
        'intro_income': 85000.0,
        'intro_persona': Persona.employee.index,
      });
      expect(find.text("What's your time worth?"), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('A little about you'), findsOneWidget);

      // Reaching step 3 fires celebrate() — a one-shot 1.4s overlay; settle
      // lets it finish so the assertion sees a stable frame.
      await tester.tap(find.widgetWithText(FilledButton, 'Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Design your Time Card'), findsOneWidget);
      expect(find.byType(TimeCard), findsAtLeastNWidgets(1));
    });
  });
}
