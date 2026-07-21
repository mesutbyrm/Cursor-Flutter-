import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/config/env.dart';
import '../core/firebase/firebase_bootstrap.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_provider.dart';
import '../core/network/token_storage.dart';
import '../core/push/push_notification_service.dart';
import 'models/auth_api_error.dart';
import 'models/auth_response.dart';
import 'models/auth_user.dart';
import 'models/apple_full_name.dart';

/// Canlifal mobil kimlik doğrulama — `https://canlifal.com` JWT API.
///
/// Access token: 7 gün · Refresh token: 30 gün · Header: `Authorization: Bearer`
class AuthService {
  AuthService({
    required Dio publicDio,
    required Dio Function() resolveAuthedDio,
    required TokenStorage tokenStorage,
  })  : _publicDio = publicDio,
        _resolveAuthedDio = resolveAuthedDio,
        _tokens = tokenStorage;

  final Dio _publicDio;
  final Dio Function() _resolveAuthedDio;
  final TokenStorage _tokens;

  Dio get _authedDio => _resolveAuthedDio();

  /// `POST /api/auth/mobile-login`
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    // Kılavuz §9.1 — `{email}` veya `{username}` + `password`.
    final body = trimmed.contains('@')
        ? {'email': trimmed, 'password': password}
        : {'username': trimmed, 'password': password};
    return _postAuth(ApiEndpoints.authMobileLogin, body);
  }

  /// `POST /api/auth/mobile-register`
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String username,
    String? birthDate,
    String? birthTime,
    String preferredLanguage = 'tr',
    String? referralCode,
  }) async {
    final data = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'username': username.trim(),
      'preferredLanguage': preferredLanguage,
      if (referralCode != null && referralCode.isNotEmpty)
        'referralCode': referralCode,
    };
    if (birthDate != null && birthDate.isNotEmpty) {
      data['birthDate'] = birthDate;
    }
    if (birthTime != null && birthTime.isNotEmpty) {
      data['birthTime'] = birthTime;
    }
    return _postAuth(ApiEndpoints.authMobileRegister, data);
  }

  /// `POST /api/auth/mobile-google`
  Future<AuthResponse> loginWithGoogle({
    required String idToken,
    String? referralCode,
  }) async {
    return _postAuth(
      ApiEndpoints.authMobileGoogle,
      {
        'idToken': idToken,
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
      },
    );
  }

  /// `POST /api/auth/mobile-apple`
  Future<AuthResponse> loginWithApple({
    required String identityToken,
    AppleFullName? fullName,
    String? referralCode,
  }) async {
    final nameJson = fullName?.toJson();
    return _postAuth(
      ApiEndpoints.authMobileApple,
      {
        'identityToken': identityToken,
        if (nameJson != null) 'fullName': nameJson,
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
      },
    );
  }

  /// `sign_in_with_apple` paketi ile kimlik bilgisi alıp API'ye gönderir.
  ///
  /// iOS Service ID: `APPLE_SERVICE_ID` (`Env.appleServiceId`).
  /// [fullName] yalnızca ilk Apple girişinde credential'dan gelir.
  Future<AuthResponse> signInWithApple({String? referralCode}) async {
    final scopes = [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ];
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: scopes,
      webAuthenticationOptions: Env.appleServiceId.trim().isNotEmpty
          ? WebAuthenticationOptions(
              clientId: Env.appleServiceId.trim(),
              redirectUri: Uri.parse(Env.appleRedirectUri),
            )
          : null,
    );
    final token = credential.identityToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('Apple kimlik jetonu alınamadı');
    }
    final name = AppleFullName.fromCredential(
      givenName: credential.givenName,
      familyName: credential.familyName,
    );
    return loginWithApple(
      identityToken: token,
      fullName: name.isEmpty ? null : name,
      referralCode: referralCode,
    );
  }

  /// `POST /api/auth/change-password` — Bearer gerekli.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authedDio.safePost<dynamic>(
      ApiEndpoints.authChangePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// `POST /api/auth/mobile-tiktok`
  Future<AuthResponse> loginWithTiktok({
    required String code,
    String? redirectUri,
    String? referralCode,
  }) async {
    final redirect = (redirectUri ?? Env.tiktokRedirectUri).trim();
    return _postAuth(
      ApiEndpoints.authMobileTiktok,
      {
        'code': code,
        if (redirect.isNotEmpty) 'redirectUri': redirect,
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
      },
    );
  }

  /// `POST /api/auth/mobile-refresh`
  Future<AuthResponse> refreshToken(String refreshToken) async {
    return _postAuth(
      ApiEndpoints.authMobileRefresh,
      {'refreshToken': refreshToken},
    );
  }

  /// `POST /api/auth/forgot-password`
  Future<void> forgotPassword(String email) async {
    await _publicDio.safePost<dynamic>(
      ApiEndpoints.authForgotPassword,
      data: {'email': email.trim().toLowerCase()},
    );
  }

  /// `POST /api/auth/reset-password`
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _publicDio.safePost<dynamic>(
      ApiEndpoints.authResetPassword,
      data: {
        'token': token.trim(),
        'password': newPassword,
      },
    );
  }

  /// `POST /api/auth/logout` + `DELETE /api/devices/fcm` + yerel temizlik.
  Future<void> logout() async {
    try {
      await _authedDio.safePost<dynamic>(ApiEndpoints.authLogout);
    } catch (e) {
      debugPrint('Auth logout API: $e');
    }

    await _deregisterFcmToken();

    await _tokens.clear();
  }

  /// Uygulama açılışında: token varsa `GET /api/me` ile doğrula.
  Future<AuthUser?> validateSession() async {
    final access = await _tokens.readAccess();
    if (access == null ||
        access.isEmpty ||
        access == TokenStorage.sessionCookieMarker) {
      return null;
    }
    try {
      final res = await _authedDio.safeGet<Map<String, dynamic>>(ApiEndpoints.me);
      final body = _unwrapBody(res.data);
      final userMap = body['user'] ?? body;
      if (userMap is! Map) return null;
      final user = AuthUser.fromJson(
        userMap is Map<String, dynamic>
            ? userMap
            : Map<String, dynamic>.from(userMap),
      );
      if (user.id.isNotEmpty) {
        await _tokens.writeUserId(user.id);
      }
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _tokens.clear();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Token + userId kalıcı depolama.
  Future<void> persistAuthResponse(AuthResponse response) async {
    await _tokens.writeTokens(
      access: response.accessToken,
      refresh: response.refreshToken,
      userId: response.user.id,
    );
  }

  Future<AuthResponse> _postAuth(String path, Map<String, dynamic> data) async {
    try {
      final res = await _publicDio.safePost<Map<String, dynamic>>(path, data: data);
      final response = AuthResponse.parseRoot(res.data);
      await persistAuthResponse(response);
      return response;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    final parsed = AuthApiError.fromResponseBody(
      e.response?.data,
      statusCode: e.response?.statusCode,
    );
    if (parsed != null) {
      return ApiException(
        parsed.message,
        statusCode: parsed.statusCode ?? e.response?.statusCode,
        errorCode: parsed.code?.name,
      );
    }
    return ApiException.fromDio(e);
  }

  Future<void> _deregisterFcmToken() async {
    if (!FirebaseBootstrap.isReady) return;
    try {
      final fcmToken =
          await PushNotificationService.instance.currentFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      await _authedDio.safeDelete(
        ApiEndpoints.registerFcmDevice,
        data: {'token': fcmToken, 'fcmToken': fcmToken},
      );
    } catch (e) {
      debugPrint('FCM deregister on logout: $e');
    }
  }

  Map<String, dynamic> _unwrapBody(Map<String, dynamic>? body) {
    if (body == null) return {};
    if (body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return body;
  }
}
