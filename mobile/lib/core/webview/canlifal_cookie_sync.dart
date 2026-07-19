import 'package:cookie_jar/cookie_jar.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Dio [CookieJar] → WebView çerez senkronu (admin SSO).
Future<void> applyPersistCookiesToWebView(CookieJar jar, String origin) async {
  final manager = WebViewCookieManager();
  final uri = Uri.parse(origin);
  final cookies = await jar.loadForRequest(uri);
  for (final c in cookies) {
    await manager.setCookie(
      WebViewCookie(
        name: c.name,
        value: c.value,
        domain: c.domain?.isNotEmpty == true ? c.domain! : uri.host,
        path: c.path?.isNotEmpty == true ? c.path! : '/',
      ),
    );
  }
}

Future<void> persistWebViewCookiesIntoJar(
  CookieJar jar,
  String origin, {
  Object? webViewController,
}) async {
  // webview_flutter çerez okuma API'si sınırlı — Dio jar birincil kaynak.
}
