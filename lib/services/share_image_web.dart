import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Web implementation. Prefers the NATIVE share sheet via the Web Share API
/// (Level 2, file sharing) — on Android Chrome / iOS Safari that is the same
/// system window WhatsApp & co. register in. Browsers that can't share files
/// (desktop Firefox, insecure contexts) get a PNG download instead.
///
/// Hand-rolled js_interop — dart:html is deprecated and package:web would be
/// a new dependency (blocked on this project).
@JS('navigator')
external JSObject get _navigator;

@JS('navigator.canShare')
external bool _canShare(JSObject data);

@JS('navigator.share')
external JSPromise<JSAny?> _share(JSObject data);

@JS('File')
extension type _JSFile._(JSObject _) implements JSObject {
  external factory _JSFile(JSArray<JSAny> bits, String name, JSObject options);
}

@JS('document.createElement')
external _Anchor _createElement(String tag);

extension type _Anchor(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

Future<String?> shareImagePlatform(Uint8List bytes, String caption) async {
  if (_navigator.has('share') && _navigator.has('canShare')) {
    JSObject? data;
    try {
      final options = JSObject()..setProperty('type'.toJS, 'image/png'.toJS);
      final file = _JSFile(
          <JSAny>[bytes.toJS].toJS, 'timewallet-card.png', options);
      final candidate = JSObject()
        ..setProperty('files'.toJS, <JSAny>[file].toJS)
        ..setProperty('text'.toJS, caption.toJS);
      if (_canShare(candidate)) data = candidate;
    } catch (_) {
      // File/share-data construction unsupported — use the download path.
    }
    if (data != null) {
      try {
        await _share(data).toDart;
      } catch (_) {
        // Rejected = the user closed the sheet; don't force a download on top.
      }
      return null;
    }
  }
  _createElement('a')
    ..href = 'data:image/png;base64,${base64Encode(bytes)}'
    ..download = 'timewallet-card.png'
    ..click();
  return 'Image downloaded — attach it anywhere.';
}
