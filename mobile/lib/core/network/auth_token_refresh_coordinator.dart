import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_endpoints.dart';
import '../network/token_storage.dart';
import '../../features/auth/data/datasources/auth_service.dart';
import '../../features/auth/data/models/auth_response.dart';

/// Eşzamanlı 401'lerde tek refresh — queue pattern.
class AuthTokenRefreshCoordinator {
  AuthTokenRefreshCoordinator._();

  static final AuthTokenRefreshCoordinator instance =
      AuthTokenRefreshCoordinator._();

  Completer<bool>? _inFlight;
  void Function()? onSessionExpired;

  /// Giriş / refresh sonrası kısa süre otomatik logout engeli.
  DateTime? _sessionFreshUntil;
  var _expiryNotified = false;

  /// Oturum yeni kuruldu — ağ gecikmesi veya geçici 401'de logout olmasın.
  void markSessionFresh({Duration grace = const Duration(seconds: 45)}) {
    _sessionFreshUntil = DateTime.now().add(grace);
    _expiryNotified = false;
  }

  bool get _inFreshGrace {
    final until = _sessionFreshUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _notifySessionExpired() {
    if (_inFreshGrace) {
      if (kDebugMode) {
        debugPrint('[Auth] session_expired suppressed (fresh grace)');
      }
      return;
    }
    if (_expiryNotified) return;
    _expiryNotified = true;
    onSessionExpired?.call();
  }

  Future<bool> _persistRefreshResponse(
    Map<String, dynamic>? data,
    TokenStorage storage,
  ) async {
    final tokens = AuthResponse.parseRefreshTokens(data);
    if (tokens == null) {
      // Eski sunucu sürümleri tam AuthResponse dönebilir.
      try {
        final response = AuthResponse.parseRoot(data);
        await storage.writeTokens(
          access: response.accessToken,
          refresh: response.refreshToken,
          userId: response.user.id,
        );
        markSessionFresh();
        return true;
      } catch (_) {
        return false;
      }
    }
    final userId = await storage.readUserId();
    await storage.writeTokens(
      access: tokens.accessToken,
      refresh: tokens.refreshToken,
      userId: userId,
    );
    markSessionFresh();
    return true;
  }

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
        _notifySessionExpired();
        return false;
      }

      try {
        final res = await refreshDio.post<Map<String, dynamic>>(
          refreshPath,
          data: {'refreshToken': refresh},
        );
        final ok = await _persistRefreshResponse(res.data, storage);
        completer.complete(ok);
        return ok;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          await storage.clear();
          _notifySessionExpired();
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
        _notifySessionExpired();
        return false;
      }

      try {
        final response = await authService.refreshToken(refresh);
        await authService.persistAuthResponse(response);
        markSessionFresh();
        completer.complete(true);
        return true;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          await storage.clear();
          _notifySessionExpired();
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

  void reset() {
    _sessionFreshUntil = null;
    _expiryNotified = false;
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
