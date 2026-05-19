import 'dart:io' as io;

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

/// WebView (Google OAuth sonrası vb.) çerezlerini [CookieJar]’a yazar; Dio istekleri oturumu görür.
Future<void> persistWebViewCookiesIntoJar(
  CookieJar jar,
  String origin, {
  InAppWebViewController? webViewController,
}) async {
  final base = origin.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse(base);
  final webCookies = await CookieManager.instance().getCookies(
    url: WebUri(base),
    webViewController: webViewController,
  );
  final out = <io.Cookie>[];
  for (final c in webCookies) {
    if (c.name.isEmpty) continue;
    final cc = io.Cookie(c.name, c.value);
    cc.path = c.path ?? '/';
    final d = c.domain;
    if (d != null && d.isNotEmpty) {
      cc.domain = d;
    }
    final exp = c.expiresDate;
    if (exp != null) {
      cc.expires = DateTime.fromMillisecondsSinceEpoch(exp);
    }
    cc.secure = c.isSecure ?? false;
    out.add(cc);
  }
  if (out.isEmpty) return;
  await jar.saveFromResponse(uri, out);
}
