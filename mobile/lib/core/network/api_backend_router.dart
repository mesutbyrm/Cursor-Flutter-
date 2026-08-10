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
    if (_isPkBackendPath(p)) return ApiBackendKind.game;
    if (_isGiftBattleBackendPath(p)) return ApiBackendKind.game;
    if (_isMembershipBackendPath(p)) return ApiBackendKind.game;
    if (_isLiveGamesBackendPath(p)) return ApiBackendKind.game;
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

  // NOT: Sesli oda PK'sı (`/api/chat/rooms/{id}/pk[...]`) ANA backend'de
  // çalışır. Production doğrulaması: canlifal.com `GET /api/chat/rooms/{id}/pk`
  // → 200, `POST /api/chat/rooms/{id}/pk/score` → 405 (route mevcut, POST
  // bekliyor); oyun backend'inde `/pk/score` → 404. Ayrıca SSE kanalı daima
  // ana backend'e bağlandığı için PK olayları yalnızca ana backend'de
  // üretildiğinde karşı tarafa ulaşır. Bu nedenle yönlendirme kuralı
  // kaldırılmıştır.

  /// Hediye savaşı / hedefi (`/api/gifts/battles`, `/api/gifts/goals`) yalnızca
  /// abacus'ta var (canlifal.com 404). Hediye gönderimi katalog ana sitede.
  static bool _isGiftBattleBackendPath(String path) =>
      path.startsWith('/api/gifts/battles') ||
      path.startsWith('/api/gifts/goals');

  /// Üyelik planları + satın alma (`/api/membership/plans`, `/purchase`) modern
  /// uçları yalnızca abacus'ta (canlifal.com'da /purchase yok → "istenilen
  /// kaynak bulunamadı"). Aynı DB, aynı plan kimlikleri.
  static bool _isMembershipBackendPath(String path) =>
      path.startsWith('/api/membership');

  /// Yalnızca oyun backend'inde bulunan canlı yayın uçları.
  /// `/api/live/pk` ve `/api/live/pk/score` ANA backend'dedir (oyun
  /// backend'inde 404) — bu yüzden burada yer almaz. `/api/live/pk/active`
  /// yalnızca oyun backend'inde 200 döner, `/api/live/guest/*` de öyle.
  static bool _isLiveGamesBackendPath(String path) =>
      path.startsWith('/api/live/pk/active') ||
      path.startsWith('/api/live/guest/');

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
