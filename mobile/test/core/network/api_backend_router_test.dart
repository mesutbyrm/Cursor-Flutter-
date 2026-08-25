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

    test('oyun kataloğu ve odalar Main backend', () {
      expect(ApiBackendRouter.resolve('/api/games'), ApiBackendKind.main);
      expect(
        ApiBackendRouter.resolve('/api/games/leaderboard', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/rooms', method: 'GET'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/rooms', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/auto-match', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/room/abc123', method: 'GET'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/room/abc123/join', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/games/play', method: 'POST'),
        ApiBackendKind.main,
      );
    });

    test('üyelik uçları Main backend', () {
      expect(
        ApiBackendRouter.resolve('/api/memberships'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/memberships/packages'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/memberships/purchase', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/membership-badges'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/membership/plans'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/membership/plans/purchase', method: 'POST'),
        ApiBackendKind.main,
      );
    });

    test('query string path normalize', () {
      expect(
        ApiBackendRouter.resolve('/api/games/rooms?limit=10'),
        ApiBackendKind.main,
      );
    });

    test('canlı PK ve misafir uçları Main backend', () {
      expect(
        ApiBackendRouter.resolve('/api/live/pk/active'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/live/guest/list'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/live/guest/list?streamId=abc'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/live/pk'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/live/pk/score', method: 'POST'),
        ApiBackendKind.main,
      );
    });

    test('birleşik PK uçları Main backend', () {
      expect(ApiBackendRouter.resolve('/api/pk/active'), ApiBackendKind.main);
      expect(
        ApiBackendRouter.resolve('/api/pk/request', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/pk/cm123/stream'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/pk/leaderboard?period=weekly'),
        ApiBackendKind.main,
      );
    });

    test('§8 dokunulmayan uçlar Main backend', () {
      expect(
        ApiBackendRouter.resolve('/api/live/gift/send', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/trtc/token', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/trtc/usersig', method: 'POST'),
        ApiBackendKind.main,
      );
    });

    test('admin hediye uçları ana site backend', () {
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts/stats'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/admin/gifts/abc123', method: 'PATCH'),
        ApiBackendKind.main,
      );
    });

    test('hediye savaşı ve hedefi Main backend (canlifal.com)', () {
      expect(
        ApiBackendRouter.resolve('/api/gifts/battles'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/gifts/battles', method: 'POST'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/gifts/battles/cm123'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/gifts/goals'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/gifts/goals', method: 'POST'),
        ApiBackendKind.main,
      );
    });

    test('sesli oda PK uçları Games backend (ana site GET stub)', () {
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
        ApiBackendRouter.resolve(
          '/api/chat/rooms/cm123/pk/score',
          method: 'POST',
        ),
        ApiBackendKind.game,
      );
      expect(
        ApiBackendRouter.resolve('/api/chat/rooms/cm123/messages'),
        ApiBackendKind.main,
      );
      expect(
        ApiBackendRouter.resolve('/api/chat/rooms/pk-list'),
        ApiBackendKind.main,
      );
    });
  });
}
