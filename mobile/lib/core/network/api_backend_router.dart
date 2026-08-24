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
  /// Tüm üretim API trafiği ana backend'e gider (`https://canlifal.com`).
  /// Eski ikinci-backend yolları (`/api/pk/*`, `/api/live/pk/active`,
  /// `/api/live/guest/*`, `/api/games/rooms`, `/api/membership/*`) ana siteye
  /// taşındı — bkz. `docs/BACKEND_API_REFERENCE.md` §3.
  ///
  /// §8 dokunulmayanlar (zaten ana backend): `/api/live/gift/send`,
  /// `/api/trtc/token`, `/api/trtc/usersig`.
  static ApiBackendKind resolve(String path, {String method = 'GET'}) {
    return ApiBackendKind.main;
  }

  static bool get hasGatewayFallback => Env.gatewayApiBaseUrl.trim().isNotEmpty;

  static bool get usesSplitBackends => Env.useSplitGamesApi;
}
