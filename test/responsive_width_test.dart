import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/widgets/responsive_body.dart';

void main() {
  group('responsiveMaxWidth', () {
    test('phones fill to the caller base', () {
      expect(responsiveMaxWidth(360, 480), 480);
      expect(responsiveMaxWidth(599, 480), 480);
    });

    test('tablets get a roomier 600 column', () {
      expect(responsiveMaxWidth(600, 480), 600);
      expect(responsiveMaxWidth(820, 480), 600);
    });

    test('desktop widths cap at 720 for readability', () {
      expect(responsiveMaxWidth(900, 480), 720);
      expect(responsiveMaxWidth(1440, 480), 720);
    });

    test('never shrinks a caller that already asked for more', () {
      expect(responsiveMaxWidth(360, 800), 800);
      expect(responsiveMaxWidth(1440, 800), 800);
    });
  });

  testWidgets('ContentWidth caps its child on a wide (tablet) viewport',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const key = Key('body');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentWidth(child: SizedBox.expand(key: key)),
        ),
      ),
    );

    // Marooned-in-dead-space bug: without the cap this would fill 1200px.
    expect(tester.getSize(find.byKey(key)).width, 720);
  });

  group('TileGrid columns adapt to width', () {
    Widget grid() => TileGrid(children: [
          Container(key: const Key('a'), height: 60),
          Container(key: const Key('b'), height: 60),
        ]);

    Future<void> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: grid())),
      );
    }

    testWidgets('phone width stacks tiles in one column', (tester) async {
      await pumpAt(tester, 400);
      final a = tester.getTopLeft(find.byKey(const Key('a')));
      final b = tester.getTopLeft(find.byKey(const Key('b')));
      expect(a.dx, b.dx, reason: 'same column');
      expect(b.dy, greaterThan(a.dy), reason: 'b sits below a');
    });

    testWidgets('tablet width puts tiles side by side', (tester) async {
      await pumpAt(tester, 1000);
      final a = tester.getTopLeft(find.byKey(const Key('a')));
      final b = tester.getTopLeft(find.byKey(const Key('b')));
      expect(a.dy, b.dy, reason: 'same row');
      expect(b.dx, greaterThan(a.dx), reason: 'b sits to the right of a');
    });
  });
}
