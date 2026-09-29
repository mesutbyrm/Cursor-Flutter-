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
  ///
  /// Çoğu üretim API trafiği ana backend'e gider (`https://canlifal.com`).
  /// Sesli oda + canlı PK REST ana sitede; SSE ile aynı origin (STAGE16 parity 2026-09).
  /// Yalnız oyun PK namespace (`/api/pk/*`) games backend'de kalır.
  ///
  /// §8 dokunulmayanlar (zaten ana backend): `/api/live/gift/send`,
  /// `/api/trtc/token`, `/api/trtc/usersig`.
  static ApiBackendKind resolve(String path, {String method = 'GET'}) {
    final p = _normalizePath(path);
    if (_isMainLivePkPath(p)) return ApiBackendKind.main;
    if (_isVoiceRoomPkPath(p)) return ApiBackendKind.main;
    if (_isMainPkUserPath(p)) return ApiBackendKind.main;
    if (_isGamesPkNamespacePath(p)) return ApiBackendKind.game;
    return ApiBackendKind.main;
  }

  static String _normalizePath(String path) {
    var p = path.trim();
    final q = p.indexOf('?');
    if (q >= 0) p = p.substring(0, q);
    if (!p.startsWith('/')) p = '/$p';
    return p;
  }

  /// `GET/POST /api/live/pk` ve `/api/live/pk/*` — ana site (zip + üretim curl).
  static bool _isMainLivePkPath(String path) {
    return path == '/api/live/pk' || path.startsWith('/api/live/pk/');
  }

  /// Sesli oda PK — `GET/POST /api/chat/rooms/{roomId}/pk[...]` (ana site).
  /// Oyun PK odaları — `/api/pk/*` (games). `POST /api/video-streams/pk` ana backend.
  static bool _isVoiceRoomPkPath(String path) {
    if (!path.startsWith('/api/chat/rooms/')) return false;
    final segments =
        path.split('/').where((segment) => segment.isNotEmpty).toList();
    // api, chat, rooms, {roomId}, pk, ...
    if (segments.length < 5) return false;
    if (segments[0] != 'api' ||
        segments[1] != 'chat' ||
        segments[2] != 'rooms') {
      return false;
    }
    return segments[4] == 'pk';
  }

  /// Oturum PK davetleri — üretimde ana site (`canlifal.com`), games değil.
  static bool _isMainPkUserPath(String path) {
    if (path == '/api/pk/me/invites') return true;
    if (path == '/api/pk/me/history') return true;
    if (path == '/api/pk/me/stats') return true;
    if (path == '/api/pk/me/matches') return true;
    return false;
  }

  /// Games backend PK — `/api/pk/*` (sesli oda `/chat/rooms/{id}/pk` ayrı).
  static bool _isGamesPkNamespacePath(String path) {
    if (path.startsWith('/api/pk/') || path == '/api/pk') return true;
    return false;
  }

  static bool get hasGatewayFallback => Env.gatewayApiBaseUrl.trim().isNotEmpty;

  static bool get usesSplitBackends => Env.useSplitGamesApi;
}
