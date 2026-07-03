import 'package:canlifal_social/core/network/api_backend_kind.dart';
import 'package:canlifal_social/core/network/api_backend_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiBackendRouter', () {
    test('auth ve profil Main backend', () {
      expect(
        ApiBackendRouter.resolve('/api/auth/mobile-login', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(ApiBackendRouter.resolve('/api/me'), ApiBackendKind.main);
      expect(ApiBackendRouter.resolve('/api/banners'), ApiBackendKind.main);
      expect(
        ApiBackendRouter.resolve('/api/social/posts'),
        ApiBackendKind.main,
      );
      expect(ApiBackendRouter.resolve('/api/shorts'), ApiBackendKind.main);
      expect(
        ApiBackendRouter.resolve('/api/homepage-fortune-cards'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/fortune-tellers'),
        ApiBackendKind.main,
      );
      expect(ApiBackendRouter.resolve('/api/chat/rooms'), ApiBackendKind.main);
      expect(ApiBackendRouter.resolve('/api/user/credits'), ApiBackendKind.main);
    });

    test('oyun kataloğu Main backend', () {
      expect(ApiBackendRouter.resolve('/api/games'), ApiBackendKind.main);
      expect(
        ApiBackendRouter.resolve('/api/games/leaderboard', method: 'POST'),
        ApiBackendKind.main,
      );
    });

    test('oyun odası uçları Game backend', () {
      expect(
        ApiBackendRouter.resolve('/api/games/rooms', method: 'GET'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/rooms', method: 'POST'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/auto-match', method: 'POST'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/room/abc123', method: 'GET'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/room/abc123/join', method: 'POST'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/play', method: 'POST'),
        ApiBackendKind.game,
      );
    });

    test('query string path normalize', () {
      expect(
        ApiBackendRouter.resolve('/api/games/rooms?limit=10'),
        ApiBackendKind.game,
      );
    });
  });
}
