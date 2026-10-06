import 'package:canlifal_social/core/network/sse/sse_connection_hub.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_discover_sse_policy.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_sse_session_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spec 7–10 + P2 — keşif SSE ile aktif oda hub lease (birim entegrasyon).
void main() {
  group('Discover SSE + hub lease (Spec 7–10 integration)', () {
    test('active room excluded but hub ref kept for in-room controller', () {
      const active = 'room-live';
      const rooms = [
        VoiceRoomEntity(id: 'room-live', slug: 'live', nameTr: 'Live'),
        VoiceRoomEntity(id: 'room-other', slug: 'other', nameTr: 'Other'),
      ];

      final discoverKeys = VoiceRoomDiscoverSsePolicy.roomKeysToTrack(
        rooms: rooms,
        maxRooms: 6,
        activeLiveKey: active,
        activeAliases: {active},
      );
      expect(discoverKeys, ['room-other']);

      final hub = SseConnectionHub();
      hub.attachVoiceRoom(active);
      hub.attachVoiceRoom(active);
      hub.attachVoiceRoom('room-other');
      expect(hub.voiceRoomRefCount(active), 2);

      hub.releaseVoiceRoom(active);
      expect(hub.voiceRoomRefCount(active), 1);
      expect(hub.voiceRoomRefCount('room-other'), 1);
    });

    test('SSE guard rejects foreign room while session active', () {
      expect(
        voiceRoomAcceptsAttachedSseEvent(
          sessionActive: true,
          attachedRoomKey: 'room-b',
          eventRoomKey: 'room-a',
          presenceApiKey: 'room-b',
        ),
        isFalse,
      );
      expect(
        voiceRoomAcceptsAttachedSseEvent(
          sessionActive: true,
          attachedRoomKey: 'room-b',
          eventRoomKey: 'room-b',
          presenceApiKey: 'room-b',
        ),
        isTrue,
      );
    });
  });
}
