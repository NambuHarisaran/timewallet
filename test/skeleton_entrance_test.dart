import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/widgets/entrance.dart';
import 'package:timewallet/widgets/feature_tile.dart';
import 'package:timewallet/widgets/skeleton.dart';

/// Phase A primitives. The disableAnimations paths matter twice over: they are
/// the reduced-motion a11y contract AND what keeps pumpAndSettle finite (a
/// repeating shimmer controller would otherwise hang the pump).
void main() {
  Widget host(Widget child, {bool reduceMotion = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: MaterialApp(home: Scaffold(body: Center(child: child))),
      );

  testWidgets('Skeleton settles under reduced motion (no repeating ticker)',
      (tester) async {
    await tester.pumpWidget(host(const Skeleton(height: 20, width: 100),
        reduceMotion: true));
    // Would time out if the shimmer controller kept repeating.
    await tester.pumpAndSettle();
    expect(find.byType(Skeleton), findsOneWidget);
  });

  testWidgets('SkeletonCard renders its placeholder lines', (tester) async {
    await tester.pumpWidget(
        host(const SkeletonCard(height: 200), reduceMotion: true));
    await tester.pumpAndSettle();
    expect(find.byType(Skeleton), findsWidgets);
  });

  testWidgets('Entrance shows child immediately under reduced motion',
      (tester) async {
    await tester.pumpWidget(
        host(const Entrance(index: 3, child: Text('hi')), reduceMotion: true));
    await tester.pump();
    // Fully settled at opacity 1 → the widget short-circuits to the raw child
    // (no Opacity/Transform wrappers left in the tree).
    expect(find.text('hi'), findsOneWidget);
    expect(find.descendant(
        of: find.byType(Entrance), matching: find.byType(Opacity)),
        findsNothing);
  });

  testWidgets('Entrance animates the child in over time', (tester) async {
    await tester.pumpWidget(host(const Entrance(index: 0, child: Text('hi'))));
    await tester.pump(); // schedule delay
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('FeatureTile fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(FeatureTile(
      icon: Icons.star,
      title: 'Title',
      subtitle: 'Sub',
      color: Colors.amber,
      onTap: () => tapped = true,
    )));
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
