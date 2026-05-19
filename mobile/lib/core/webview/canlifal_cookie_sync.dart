import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Dio [PersistCookieJar] çerezlerini InAppWebView’a aktarır (NextAuth oturumu).
Future<void> applyPersistCookiesToWebView(CookieJar jar, String origin) async {
  final base = origin.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse(base);
  final list = await jar.loadForRequest(uri);
  final cm = CookieManager.instance();
  for (final c in list) {
    try {
      await cm.setCookie(
        url: WebUri(base),
        name: c.name,
        value: c.value,
        path: c.path ?? '/',
        domain: c.domain,
        expiresDate: c.expires?.millisecondsSinceEpoch,
        isSecure: c.secure,
        isHttpOnly: c.httpOnly,
      );
    } catch (_) {}
  }
}
