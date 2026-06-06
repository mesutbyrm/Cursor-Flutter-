import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/env.dart';
import '../../../../core/config/google_auth_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';

/// Google / TikTok — native SDK + canlifal.com mobil JWT API.
class NativeAuthDataSource {
  NativeAuthDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> signInWithGoogle({String? referralCode}) async {
    final serverId = GoogleAuthConfig.serverClientId;
    if (serverId == null || serverId.isEmpty) {
      throw ApiException(
        'Google giriş yapılandırılmamış.\n\n'
        '${GoogleAuthConfig.setupHint}',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverId,
    );

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      debugPrint('Google signIn PlatformException: ${e.code} ${e.message}');
      final code = e.code.toLowerCase();
      if (code.contains('sign_in_canceled') || code.contains('canceled')) {
        throw const ApiException('Google giriş iptal edildi');
      }
      if (code.contains('network')) {
        throw const ApiException(
          'Google bağlantı hatası. İnternetinizi kontrol edin.',
        );
      }
      if (code.contains('sign_in_failed') || code.contains('10')) {
        throw ApiException(
          'Google giriş başarısız (SHA-1 / OAuth yapılandırması). '
          'Firebase Console\'da Android uygulamasına debug ve release SHA-1 '
          'parmak izlerini ekleyin.\n\n'
          'cd mobile/android && ./gradlew signingReport',
        );
      }
      throw ApiException(
        e.message?.isNotEmpty == true
            ? e.message!
            : 'Google giriş başarısız (${e.code})',
      );
    } catch (e) {
      debugPrint('Google signIn: $e');
      throw ApiException(
        'Google giriş başarısız: ${ApiException.userMessage(e)}',
      );
    }

    if (account == null) {
      throw const ApiException('Google giriş iptal edildi');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(
        'Google kimlik jetonu alınamadı.\n\n'
        '${GoogleAuthConfig.setupHint}',
      );
    }

    if (!Env.useMobileAuth) {
      debugPrint(
        'Google: API_BASE_URL canlifal.com değil — mobil-google uçları çalışmayabilir.',
      );
    }

    try {
      final res = await _dio.safePost<Map<String, dynamic>>(
        ApiEndpoints.authMobileGoogle,
        data: {
          'idToken': idToken,
          if (referralCode != null && referralCode.isNotEmpty)
            'referralCode': referralCode,
        },
      );
      return _unwrapAuthResponse(res.data);
    } on ApiException catch (e) {
      debugPrint('mobile-google API: ${e.statusCode} ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signInWithTikTok({String? referralCode}) async {
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

    final path = Env.useMobileAuth
        ? ApiEndpoints.authMobileTiktok
        : ApiEndpoints.authTiktok;
    final res = await _dio.safePost<Map<String, dynamic>>(
      path,
      data: {
        'code': code,
        if (!Env.useMobileAuth) 'redirectUri': redirect,
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
      },
    );
    return _unwrapAuthResponse(res.data);
  }

  /// canlifal.com düz JSON veya `{ success, data }` sarmalayıcı.
  Map<String, dynamic> _unwrapAuthResponse(Map<String, dynamic>? body) {
    if (body == null) return {};
    if (body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return body;
  }
}
