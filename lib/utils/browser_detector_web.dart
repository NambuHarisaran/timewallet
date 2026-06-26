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
