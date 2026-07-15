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

    test('canlı PK ve misafir uçları Game backend', () {
      expect(
        ApiBackendRouter.resolve('/api/live/pk/active'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/live/pk/sweep', method: 'POST'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/live/guest/list'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/live/guest/list?streamId=abc'),
        ApiBackendKind.game,
      );
    });

    test('birleşik PK uçları Game backend', () {
      expect(ApiBackendRouter.resolve('/api/pk/active'), ApiBackendKind.game);
      expect(
        ApiBackendRouter.resolve('/api/pk/request', method: 'POST'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/pk/cm123/stream'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/pk/leaderboard?period=weekly'),
        ApiBackendKind.game,
      );
    });

    test('admin hediye uçları Game backend', () {
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts/upload-url', method: 'POST'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts/statistics'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts/revenue/rules'),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts/abc123', method: 'PATCH'),
        ApiBackendKind.game,
      );
    });

    test('sesli oda PK uçları Game backend', () {
      expect(
        ApiBackendRouter.resolve(
          '/api/chat/rooms/cm123/pk',
        ),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve(
          '/api/chat/rooms/cm123/pk/inv-1/respond',
          method: 'POST',
        ),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve(
          '/api/chat/rooms/cm123/pk/battle-1/end',
          method: 'POST',
        ),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/chat/rooms/cm123/messages'),
        ApiBackendKind.main,
      );
    });
  });
}
