import 'package:flutter/foundation.dart' show kIsWeb;

/// API tabanı. Derleme sırasında:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://canlifal.com',
  );

  /// Herkese açık web sitesi kökü — statik varlıklar (arka planlar,
  /// `/images/...`) her zaman burada barınır; API host (apiBaseUrl) farklı
  /// olabilir ve bu varlıkları sunmaz.
  static const String webOrigin = String.fromEnvironment(
    'WEB_ORIGIN',
    defaultValue: 'https://canlifal.com',
  );

  /// Oyun odası uçları (Redis / Backend-2).
  static const String gamesApiBaseUrl = String.fromEnvironment(
    'GAMES_API_BASE_URL',
    defaultValue: 'https://canlifalapi.abacusai.app',
  );

  /// Acil gateway yedeği — yalnızca 502/503/504 sonrası tek deneme.
  static const String gatewayApiBaseUrl = String.fromEnvironment(
    'GATEWAY_API_BASE_URL',
    defaultValue: '',
  );

  static bool get useSplitGamesApi {
    final main = apiBaseUrl.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
    final games =
        gamesApiBaseUrl.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
    return games.isNotEmpty && games != main;
  }

  /// Mobil JWT (`/api/auth/mobile-*`, `/api/me`). WebView OAuth yok.
  static bool get useMobileAuth {
    final u = apiBaseUrl.toLowerCase();
    if (u.contains('.local') ||
        u.contains('127.0.0.1') ||
        u.contains('localhost')) {
      return false;
    }
    return u.contains('canlifal.com') ||
        u.contains('canlifalapi.abacusai.app') ||
        u.contains('abacusai.app');
  }

  /// `/api` önekli istek tabanı (örn. `…/api/games/rooms`).
  static String get apiPrefixUrl {
    final origin = siteOrigin;
    if (origin.endsWith('/api')) return origin;
    return '$origin/api';
  }

  /// Geriye dönük: canlı site oturumu (JWT ile aynı taban).
  static bool get useNextAuth => useMobileAuth;

  static String get siteOrigin {
    var u = apiBaseUrl.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  /// Google Sign-In server client ID (OAuth 2.0 Web client).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static const String tiktokClientKey = String.fromEnvironment(
    'TIKTOK_CLIENT_KEY',
    defaultValue: '',
  );

  static const String tiktokRedirectUri = String.fromEnvironment(
    'TIKTOK_REDIRECT_URI',
    defaultValue: 'canlifal://tiktok-auth',
  );

  /// Apple Sign-In Service ID (iOS / Android web auth).
  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: '',
  );

  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://canlifal.com/api/auth/callback/apple',
  );

  static bool get hasAppleLogin => appleServiceId.trim().isNotEmpty;

  static bool get hasTikTokLogin =>
      tiktokClientKey.trim().isNotEmpty && !kIsWeb;

  /// Sesli sohbet Agora — App ID only (token yok).
  static const agoraVoiceAppId = String.fromEnvironment(
    'AGORA_VOICE_APP_ID',
    defaultValue: 'f1cf983a38114b04a4e9102c303ba63e',
  );

  /// `auto` | `livekit` | `trtc` | `agora` — sesli oda ses motoru.
  static const String voiceEngine = String.fromEnvironment(
    'VOICE_ENGINE',
    defaultValue: 'auto',
  );

  static bool get preferLiveKit =>
      voiceEngine == 'livekit' ||
      (voiceEngine == 'auto' && !kIsWeb);

  static bool get forceTrtc => voiceEngine == 'trtc';
}
