import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/token_storage.dart';
import '../../../core/webview/canlifal_cookie_sync.dart';
import '../domain/admin_web_config.dart';

/// JWT → WebView oturumu: çerez senkronu + bootstrap HTML.
class AdminWebSsoService {
  AdminWebSsoService({
    required TokenStorage tokenStorage,
    required CookieJar cookieJar,
    required Dio dio,
  })  : _tokens = tokenStorage,
        _cookieJar = cookieJar,
        _dio = dio;

  final TokenStorage _tokens;
  final CookieJar _cookieJar;
  final Dio _dio;

  Future<AdminWebSsoPayload> prepareSession() async {
    final access = await _tokens.readAccess();
    if (access == null || access.isEmpty) {
      throw StateError('Oturum bulunamadı');
    }

    await applyPersistCookiesToWebView(_cookieJar, AdminWebConfig.origin);

    // Sunucu SSO uçları (varsa) — sessizce dene.
    await _tryServerBridge(access);

    final bootstrap = _buildBootstrapHtml(access);
    return AdminWebSsoPayload(
      bootstrapHtml: bootstrap,
      accessToken: access,
      targetUrl: AdminWebConfig.adminEntryUri(accessToken: access).toString(),
      requestHeaders: {
        'Authorization': 'Bearer $access',
        'X-Canlifal-Mobile': '1',
        'X-Canlifal-Platform': defaultTargetPlatform.name,
      },
    );
  }

  Future<void> _tryServerBridge(String access) async {
    final refresh = await _tokens.readRefresh();
    final candidates = [
      '/api/mobile/auth/web-session',
      '/api/admin/mobile-auth',
    ];
    for (final path in candidates) {
      try {
        await _dio.post<dynamic>(
          path,
          data: {
            'accessToken': access,
            if (refresh != null && refresh.isNotEmpty)
              'refreshToken': refresh,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $access'},
            validateStatus: (s) => s != null && s < 500,
          ),
        );
      } catch (_) {
        // SSO uçları opsiyonel — yoksa bootstrap devreye girer.
      }
    }
  }

  String _buildBootstrapHtml(String access) {
    final tokenJson = jsonEncode(access);
    final adminUrl = AdminWebConfig.adminUri.toString();
    return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Canlifal Admin</title>
<style>body{margin:0;background:#0d0d12;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh}</style>
</head>
<body>
<p id="s">Oturum hazırlanıyor…</p>
<script>
(function(){
  var token = $tokenJson;
  try {
    localStorage.setItem('canlifal_mobile_access_token', token);
    sessionStorage.setItem('canlifal_mobile_access_token', token);
    document.cookie = 'canlifal_mobile_jwt=' + encodeURIComponent(token) + '; path=/; secure; samesite=lax';
  } catch(e) {}

  function withAuth(init) {
    init = init || {};
    var headers = init.headers || {};
    if (headers instanceof Headers) {
      headers.set('Authorization', 'Bearer ' + token);
      headers.set('X-Canlifal-Mobile', '1');
    } else {
      headers['Authorization'] = 'Bearer ' + token;
      headers['X-Canlifal-Mobile'] = '1';
      init.headers = headers;
    }
    init.credentials = 'include';
    return init;
  }

  var origFetch = window.fetch;
  window.fetch = function(input, init) {
    return origFetch.call(this, input, withAuth(init));
  };

  var XHR = XMLHttpRequest.prototype;
  var open = XHR.open;
  var send = XHR.send;
  XHR.open = function(method, url) {
    this._url = url;
    return open.apply(this, arguments);
  };
  XHR.send = function(body) {
    try { this.setRequestHeader('Authorization', 'Bearer ' + token); } catch(e) {}
    try { this.setRequestHeader('X-Canlifal-Mobile', '1'); } catch(e) {}
    return send.call(this, body);
  };

  window.location.replace(${jsonEncode(adminUrl)});
})();
</script>
</body>
</html>
''';
  }
}

class AdminWebSsoPayload {
  const AdminWebSsoPayload({
    required this.bootstrapHtml,
    required this.accessToken,
    required this.targetUrl,
    required this.requestHeaders,
  });

  final String bootstrapHtml;
  final String accessToken;
  final String targetUrl;
  final Map<String, String> requestHeaders;
}
