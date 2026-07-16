import 'dart:async';

import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/token_storage.dart';
import '../../services/auth_service.dart';
import '../../services/models/auth_response.dart';

/// Eşzamanlı 401'lerde tek refresh — queue pattern.
class AuthTokenRefreshCoordinator {
  AuthTokenRefreshCoordinator._();

  static final AuthTokenRefreshCoordinator instance =
      AuthTokenRefreshCoordinator._();

  Completer<bool>? _inFlight;
  void Function()? onSessionExpired;

  /// Dio interceptor — [AuthService] veya legacy refresh.
  Future<bool> refreshLegacy({
    required Dio refreshDio,
    required TokenStorage storage,
    String refreshPath = ApiEndpoints.authMobileRefresh,
  }) async {
    if (_inFlight != null) {
      return _inFlight!.future;
    }

    final completer = Completer<bool>();
    _inFlight = completer;

    try {
      final refresh = await storage.readRefresh();
      if (refresh == null || refresh.isEmpty) {
        completer.complete(false);
        onSessionExpired?.call();
        return false;
      }

      try {
        final res = await refreshDio.post<Map<String, dynamic>>(
          refreshPath,
          data: {'refreshToken': refresh},
        );
        final response = AuthResponse.parseRoot(res.data);
        await storage.writeTokens(
          access: response.accessToken,
          refresh: response.refreshToken,
          userId: response.user.id,
        );
        completer.complete(true);
        return true;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          await storage.clear();
          onSessionExpired?.call();
        }
        completer.complete(false);
        return false;
      } catch (_) {
        completer.complete(false);
        return false;
      }
    } finally {
      _inFlight = null;
    }
  }

  /// Açık refresh — [AuthService.refreshToken] ile aynı sözleşme.
  Future<bool> refresh({
    required AuthService authService,
    required TokenStorage storage,
  }) async {
    if (_inFlight != null) {
      return _inFlight!.future;
    }

    final completer = Completer<bool>();
    _inFlight = completer;

    try {
      final refresh = await storage.readRefresh();
      if (refresh == null || refresh.isEmpty) {
        completer.complete(false);
        onSessionExpired?.call();
        return false;
      }

      try {
        final response = await authService.refreshToken(refresh);
        await authService.persistAuthResponse(response);
        completer.complete(true);
        return true;
      } catch (_) {
        await storage.clear();
        onSessionExpired?.call();
        completer.complete(false);
        return false;
      }
    } finally {
      _inFlight = null;
    }
  }
}

/// Geriye dönük — SSE ve bildirim kanalları.
Future<bool> tryRefreshAccessTokenLegacy(
  Dio dio,
  TokenStorage storage, {
  String? refreshPath,
}) {
  return AuthTokenRefreshCoordinator.instance.refreshLegacy(
    refreshDio: dio,
    storage: storage,
    refreshPath: refreshPath ?? ApiEndpoints.authMobileRefresh,
  );
}
