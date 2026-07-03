import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/widgets/empty_preview.dart';

/// X9 — empty states should sell the value with a faded preview + one live CTA.
/// The preview must be non-interactive; only the CTA fires.
void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('shows title, preview and a working CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(EmptyPreview(
      title: 'BUDGETS',
      preview: const Text('preview-bars'),
      cta: 'Set a budget',
      onTap: () => tapped = true,
    )));

    expect(find.text('BUDGETS'), findsOneWidget);
    expect(find.text('preview-bars'), findsOneWidget);

    await tester.tap(find.text('Set a budget'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('preview is excluded from semantics (only CTA is actionable)',
      (tester) async {
    await tester.pumpWidget(host(EmptyPreview(
      title: 'GOALS',
      preview: const Text('fake goal'),
      cta: 'Add goal',
      onTap: () {},
    )));
    // Wrapped in ExcludeSemantics + IgnorePointer → preview is inert.
    expect(find.byType(ExcludeSemantics), findsWidgets);
    expect(find.byType(IgnorePointer), findsWidgets);
    expect(find.text('fake goal'), findsOneWidget);
  });
}
