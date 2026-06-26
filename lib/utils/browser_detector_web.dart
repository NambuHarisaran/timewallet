// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

bool isSessionStorageSupported() {
  try {
    final result = js.context.callMethod('eval', [
      "(function() { try { sessionStorage.setItem('test_ss', '1'); sessionStorage.removeItem('test_ss'); return true; } catch(e) { return false; } })()"
    ]);
    return result == true;
  } catch (_) {
    return false;
  }
}

bool isInAppWebView() {
  try {
    final userAgent = js.context['navigator']['userAgent'] as String? ?? '';
    final rules = [
      'FBAN', 'FBAV',
      'Instagram',
      'Snapchat',
      'Twitter',
      'Line',
      'WhatsApp',
      'Discord',
      'LinkedInApp',
      'WeChat',
      'MicroMessenger',
      'webview',
      'wv',
    ];
    return rules.any((rule) => userAgent.toLowerCase().contains(rule.toLowerCase()));
  } catch (_) {
    return false;
  }
}

/// Detects mobile browsers (Android, iPhone, iPad, iPod) where signInWithPopup
/// often fails because mobile Chrome converts popups into redirects, breaking
/// the sessionStorage-based state handshake.
bool isMobileWeb() {
  try {
    final userAgent = js.context['navigator']['userAgent'] as String? ?? '';
    return RegExp(r'Android|iPhone|iPad|iPod|Mobile', caseSensitive: false)
        .hasMatch(userAgent);
  } catch (_) {
    return false;
  }
}
