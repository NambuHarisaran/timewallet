import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('timewallet/share');

/// IO implementation. Android opens the system share sheet through a
/// hand-rolled platform channel — share_plus can't be added on this project
/// (the Defender/DDC file-lock blocks new packages), so MainActivity handles
/// the ACTION_SEND intent itself. Platforms without the channel (Windows
/// desktop, tests without a mock) fall back to saving the PNG to a temp file
/// and reporting where it went.
Future<String?> shareImagePlatform(Uint8List bytes, String caption) async {
  try {
    await _channel
        .invokeMethod('shareImage', {'bytes': bytes, 'caption': caption});
    return null; // Share sheet opened — nothing more to tell the user.
  } on PlatformException {
    // Native side failed — fall through to the file fallback.
  } on MissingPluginException {
    // No handler on this platform — fall through.
  }
  final dir = await Directory.systemTemp.createTemp('timewallet-share');
  final file = File('${dir.path}${Platform.pathSeparator}timewallet-card.png');
  await file.writeAsBytes(bytes, flush: true);
  return 'Saved to ${file.path}';
}
