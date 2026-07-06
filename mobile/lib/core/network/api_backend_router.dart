import '../config/env.dart';
import 'api_backend_kind.dart';

/// Her API path'i doğrudan doğru backend'e yönlendirir.
/// Gateway fallback normal akış değildir — yalnızca [GatewayFallbackInterceptor].
abstract final class ApiBackendRouter {
  static String baseUrlFor(ApiBackendKind kind) => switch (kind) {
        ApiBackendKind.main => Env.apiBaseUrl,
        ApiBackendKind.game => Env.gamesApiBaseUrl,
        ApiBackendKind.gateway => Env.gatewayApiBaseUrl,
      };

  /// İstek path'ine göre hedef backend (gateway hariç).
  static ApiBackendKind resolve(String path, {String method = 'GET'}) {
    final p = _normalizePath(path);
    if (p == '/api/v1/health') return ApiBackendKind.game;
    if (_isPkBackendPath(p)) return ApiBackendKind.game;
    if (_isAdminGiftsBackendPath(p)) return ApiBackendKind.game;
    if (_isGameBackendPath(p, method)) return ApiBackendKind.game;
    return ApiBackendKind.main;
  }

  static String _normalizePath(String path) {
    var p = path.trim();
    final q = p.indexOf('?');
    if (q >= 0) p = p.substring(0, q);
    if (!p.startsWith('/')) p = '/$p';
    return p;
  }

  /// Birleşik PK sistemi (Faz 1–3) — `canlifalapi.abacusai.app`.
  static bool _isPkBackendPath(String path) => path.startsWith('/api/pk');

  /// Admin hediye kataloğu CRUD + yükleme — `canlifalapi.abacusai.app`.
  static bool _isAdminGiftsBackendPath(String path) =>
      path.startsWith('/api/admin/gifts');

  /// Oyun **odası** uçları — Redis backend (Backend-2).
  static bool _isGameBackendPath(String path, String method) {
    if (path == '/api/games/rooms') return true;
    if (path == '/api/games/auto-match') return true;
    if (path.startsWith('/api/games/room')) return true;
    if (path == '/api/games/play') return true;
    // Katalog, skor, turnuva ana sitede kalır.
    return false;
  }

  static bool get hasGatewayFallback => Env.gatewayApiBaseUrl.trim().isNotEmpty;

  static bool get usesSplitBackends => Env.useSplitGamesApi;
}
