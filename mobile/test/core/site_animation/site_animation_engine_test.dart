import 'package:canlifal_social/core/site_animation/application/site_animation_manager.dart';
import 'package:canlifal_social/core/site_animation/data/site_animation_parser.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SiteAnimationTier', () {
    test('queue priority matches spec scale', () {
      expect(SiteAnimationTier.normal.queuePriority, 10);
      expect(SiteAnimationTier.gold.queuePriority, 30);
      expect(SiteAnimationTier.diamond.queuePriority, 60);
      expect(SiteAnimationTier.vip.queuePriority, 80);
      expect(SiteAnimationTier.svip.queuePriority, 90);
      expect(SiteAnimationTier.admin.queuePriority, 100);
    });
  });

  group('SiteAnimationParser', () {
    test('maps user_joined gold membership', () {
      final cmd = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'evt-gold-1',
          'userId': 'u1',
          'name': 'Altın Üye',
          'membership': 'gold',
        },
      );
      expect(cmd, isNotNull);
      expect(cmd!.type, SiteAnimationType.memberJoined);
      expect(cmd.tier, SiteAnimationTier.gold);
      expect(cmd.eventId, 'evt-gold-1');
    });

    test('maps ROOM_MEMBER_LEFT alias', () {
      final cmd = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'ROOM_MEMBER_LEFT',
        payload: {
          'eventId': 'evt-left',
          'userId': 'u2',
          'name': 'Ayrılan',
        },
      );
      expect(cmd?.type, SiteAnimationType.memberLeft);
    });

    test('maps seat_changed with previous seat', () {
      final cmd = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'seat_changed',
        payload: {
          'eventId': 'evt-seat',
          'userId': 'u3',
          'seatIndex': 4,
          'previousSeatIndex': 2,
        },
      );
      expect(cmd?.type, SiteAnimationType.seatChanged);
      expect(cmd?.layout.fromSeatIndex, 2);
      expect(cmd?.layout.seatIndex, 4);
    });

    test('respects admin animation position override', () {
      final cmd = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'evt-admin',
          'userId': 'admin1',
          'chatRole': 'admin',
          'animation': {
            'anchor': 'TOP_CENTER',
            'scale': 1.2,
            'durationMs': 3000,
          },
        },
      );
      expect(cmd?.tier, SiteAnimationTier.admin);
      expect(cmd?.layout.scale, 1.2);
      expect(cmd?.layout.durationMs, 3000);
    });

    test('mic_changed maps to mic on/off', () {
      final on = SiteAnimationParser.fromRoomEvent(
        roomId: 'r',
        event: 'mic_changed',
        payload: {'userId': 'u', 'micOn': true},
      );
      final off = SiteAnimationParser.fromRoomEvent(
        roomId: 'r',
        event: 'mic_changed',
        payload: {'userId': 'u', 'micOn': false},
      );
      expect(on?.type, SiteAnimationType.micEnabled);
      expect(off?.type, SiteAnimationType.micDisabled);
    });

    test('seat_rank_glow maps to seat glow with seat anchor', () {
      final cmd = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'seat_rank_glow',
        payload: {
          'eventId': 'evt-glow',
          'userId': 'u1',
          'name': 'Gold Koltuk',
          'membership': 'gold',
          'seatIndex': 3,
        },
      );
      expect(cmd?.type, SiteAnimationType.seatRankGlow);
      expect(cmd?.layout.seatIndex, 3);
      expect(cmd?.tier, SiteAnimationTier.gold);
    });

    test('uses server animation metadata from enriched room_event', () {
      final cmd = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'evt-server',
          'userId': 'u1',
          'membership': 'gold',
          'animation': {
            'id': 'anim_entrance_gold_crown',
            'assetUrl': 'assets/gifts/lottie/crown.json',
            'assetType': 'lottie',
            'anchor': 'TOP_LEFT',
            'durationMs': 3000,
          },
        },
      );
      expect(cmd?.asset?.bundlePath, 'assets/gifts/lottie/crown.json');
      expect(cmd?.layout.durationMs, 3000);
    });
  });

  group('SiteAnimationManager', () {
    test('dedupes duplicate eventId', () {
      final managerWithListener = SiteAnimationManager(
        onStateChanged: (_) {},
      );

      final cmd = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'dup-1',
          'userId': 'u1',
          'membership': 'gold',
        },
      )!;

      managerWithListener.play(cmd);
      managerWithListener.play(cmd);
      expect(managerWithListener.state.active?.eventId, 'dup-1');
      expect(managerWithListener.state.queueLength, 0);

      managerWithListener.dispose();
    });

    test('queues by priority — admin before normal', () {
      final manager = SiteAnimationManager();
      final normal = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {'eventId': 'n1', 'userId': 'n', 'membership': 'basic'},
      )!;
      final admin = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'a1',
          'userId': 'a',
          'chatRole': 'admin',
        },
      )!;

      manager.play(normal);
      manager.play(admin);
      expect(manager.state.active?.eventId, 'n1');
      expect(manager.state.queueLength, 1);
      expect(manager.state.queueLength, 1);
      manager.onActiveFinished('n1');
      expect(manager.state.active?.tier, SiteAnimationTier.admin);

      manager.dispose();
    });

    test('clearQueue and cancel work', () {
      final manager = SiteAnimationManager();
      final first = SiteAnimationParser.fromRoomEvent(
        roomId: 'r',
        event: 'user_joined',
        payload: {'eventId': 'f', 'userId': '1'},
      )!;
      final second = SiteAnimationParser.fromRoomEvent(
        roomId: 'r',
        event: 'user_joined',
        payload: {'eventId': 's', 'userId': '2', 'membership': 'gold'},
      )!;

      manager.play(first);
      manager.play(second);
      manager.cancel('s');
      expect(manager.state.queueLength, 0);

      manager.play(second);
      manager.clearQueue();
      expect(manager.state.queueLength, 0);

      manager.dispose();
    });

    test('respects cooldownMs per user animation key', () {
      final manager = SiteAnimationManager();
      final first = SiteAnimationParser.fromRoomEvent(
        roomId: 'r',
        event: 'user_joined',
        payload: {'eventId': 'c1', 'userId': 'u1', 'membership': 'gold'},
      )!.copyWith(cooldownMs: 60000, animationId: 'anim_entrance_gold_crown');
      final second = SiteAnimationParser.fromRoomEvent(
        roomId: 'r',
        event: 'user_joined',
        payload: {'eventId': 'c2', 'userId': 'u1', 'membership': 'gold'},
      )!.copyWith(cooldownMs: 60000, animationId: 'anim_entrance_gold_crown');

      manager.play(first);
      manager.play(second);
      expect(manager.state.active?.eventId, 'c1');
      expect(manager.state.queueLength, 0);

      manager.dispose();
    });
  });
}
