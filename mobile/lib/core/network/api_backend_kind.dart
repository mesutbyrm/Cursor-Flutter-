/// Hangi fiziksel backend'e istek gideceğini belirler.
enum ApiBackendKind {
  /// Ana platform — canlifal.com (fal, sosyal, video, auth, sesli oda, jeton).
  main,

  /// Oyun odaları — canlifalapi.abacusai.app (Redis, /api/games/room*).
  game,

  /// Acil durum gateway yedeği (502/503/504 sonrası tek seferlik).
  gateway,
}

extension ApiBackendKindX on ApiBackendKind {
  String get label => switch (this) {
        ApiBackendKind.main => 'Main',
        ApiBackendKind.game => 'Game',
        ApiBackendKind.gateway => 'Gateway',
      };
}
