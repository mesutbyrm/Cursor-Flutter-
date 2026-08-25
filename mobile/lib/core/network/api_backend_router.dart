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
  /// Sesli oda PK REST (`/api/chat/rooms/{id}/pk*`) games backend'dedir —
  /// ana sitede GET stub (`null`) döner; kılavuz §9.3 ve `PK_VOICE_ROOM_PARITY.md`.
  ///
  /// §8 dokunulmayanlar (zaten ana backend): `/api/live/gift/send`,
  /// `/api/trtc/token`, `/api/trtc/usersig`.
  static ApiBackendKind resolve(String path, {String method = 'GET'}) {
    final p = _normalizePath(path);
    if (_isVoiceRoomPkPath(p)) return ApiBackendKind.game;
    return ApiBackendKind.main;
  }

  static String _normalizePath(String path) {
    var p = path.trim();
    final q = p.indexOf('?');
    if (q >= 0) p = p.substring(0, q);
    if (!p.startsWith('/')) p = '/$p';
    return p;
  }

  /// Sesli oda PK — `GET/POST /api/chat/rooms/{roomId}/pk[...]`.
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

  static bool get hasGatewayFallback => Env.gatewayApiBaseUrl.trim().isNotEmpty;

  static bool get usesSplitBackends => Env.useSplitGamesApi;
}
