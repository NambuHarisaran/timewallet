import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'share_image_io.dart' if (dart.library.html) 'share_image_web.dart'
    as platform;

/// Captures a widget as a PNG and hands it to the platform share path.
/// Pure-SDK: RepaintBoundary rasterisation + a platform channel, no plugins.
class ShareService {
  /// Renders the RepaintBoundary under [key] to PNG bytes, upscaled so the
  /// export is ~[targetWidth]px wide regardless of the device's screen.
  static Future<Uint8List?> capturePng(GlobalKey key,
      {double targetWidth = 1080}) async {
    final obj = key.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) return null;
    final w = obj.size.width;
    final ratio = w > 0 ? (targetWidth / w).clamp(1.0, 5.0) : 3.0;
    final image = await obj.toImage(pixelRatio: ratio.toDouble());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Opens the share sheet (Android) or downloads/saves the PNG elsewhere.
  /// Returns a user-facing message when there's something to tell (file
  /// saved, downloaded), or null when the share sheet took over.
  static Future<String?> shareImage(Uint8List bytes, {String caption = ''}) =>
      platform.shareImagePlatform(bytes, caption);
}
