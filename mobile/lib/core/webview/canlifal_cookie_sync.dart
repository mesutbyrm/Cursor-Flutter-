import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

/// WebView kaldırıldı — çerez senkronu yalnızca Dio [CookieJar] üzerinden.
Future<void> applyPersistCookiesToWebView(CookieJar jar, String origin) async {
  // No-op: native JWT oturumu kullanılıyor.
}

Future<void> persistWebViewCookiesIntoJar(
  CookieJar jar,
  String origin, {
  Object? webViewController,
}) async {
  // No-op: WebView yok.
}
