import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/features/share/share_card_screen.dart';
import 'package:timewallet/services/share_image_io.dart';

/// Share card: PNG export path + the "Tracked by TimeWallet" badge that must
/// ride along on every exported image.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('card renders headline, badge and share button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ShareCardScreen(headline: 'That costs 3 hours of my life'),
        ),
      ),
    );
    expect(find.text('That costs 3 hours of my life'), findsOneWidget);
    expect(find.text('Tracked by TimeWallet'), findsOneWidget);
    expect(find.text('Share as image'), findsOneWidget);
  });

  testWidgets('badge lives inside the exported RepaintBoundary',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ShareCardScreen(headline: 'X')),
      ),
    );
    // The badge must be a descendant of a RepaintBoundary that also holds the
    // headline — otherwise exports would ship without the brand mark.
    final boundary = find.ancestor(
      of: find.text('Tracked by TimeWallet'),
      matching: find.byType(RepaintBoundary),
    );
    expect(boundary, findsWidgets);
    expect(
      find.descendant(of: boundary.first, matching: find.text('X')),
      findsOneWidget,
    );
  });

  test('shareImagePlatform sends bytes + caption over the channel', () async {
    const channel = MethodChannel('timewallet/share');
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      received = call;
      return true;
    });

    final bytes = Uint8List.fromList([1, 2, 3]);
    final msg = await shareImagePlatform(bytes, 'caption here');

    expect(msg, isNull); // share sheet handled it — no message for the user
    expect(received?.method, 'shareImage');
    expect(received?.arguments['bytes'], bytes);
    expect(received?.arguments['caption'], 'caption here');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('channel failure falls back to saving the PNG', () async {
    const channel = MethodChannel('timewallet/share');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'SHARE_FAILED');
    });

    final msg = await shareImagePlatform(Uint8List.fromList([1]), '');
    expect(msg, isNotNull);
    expect(msg, contains('Saved to'));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
