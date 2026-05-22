import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';

/// Google / TikTok — WebView yok, SQL API (`/api/auth/google`, `/api/auth/tiktok`).
class NativeAuthDataSource {
  NativeAuthDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> signInWithGoogle() async {
    final serverId = Env.googleServerClientId.trim();
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverId.isNotEmpty ? serverId : null,
    );

    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google signIn: $e');
      throw const ApiException('Google giriş iptal edildi veya başarısız');
    }
    if (account == null) {
      throw const ApiException('Google giriş iptal edildi');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const ApiException(
        'Google kimlik jetonu alınamadı. GOOGLE_SERVER_CLIENT_ID tanımlayın.',
      );
    }

    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authGoogle,
      data: {'idToken': idToken},
    );
    return _unwrap(res.data);
  }

  Future<Map<String, dynamic>> signInWithTikTok() async {
    final clientKey = Env.tiktokClientKey.trim();
    if (clientKey.isEmpty) {
      throw const ApiException('TikTok girişi yapılandırılmamış');
    }

    final redirect = Env.tiktokRedirectUri.trim();
    final start = Uri.https('www.tiktok.com', '/v2/auth/authorize/', {
      'client_key': clientKey,
      'scope': 'user.info.basic',
      'response_type': 'code',
      'redirect_uri': redirect,
    });

    final resultUrl = await FlutterWebAuth2.authenticate(
      url: start.toString(),
      callbackUrlScheme: Uri.parse(redirect).scheme,
    );

    final code = Uri.parse(resultUrl).queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const ApiException('TikTok yetkilendirme kodu alınamadı');
    }

    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authTiktok,
      data: {'code': code, 'redirectUri': redirect},
    );
    return _unwrap(res.data);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) return {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return body;
  }
}
