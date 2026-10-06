import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_discover_sse_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomDiscoverSsePolicy', () {
    test('active room excluded from discover keys', () {
      const rooms = [
        VoiceRoomEntity(id: 'room-a', slug: 'a', nameTr: 'A'),
        VoiceRoomEntity(id: 'room-b', slug: 'b', nameTr: 'B'),
      ];
      final keys = VoiceRoomDiscoverSsePolicy.roomKeysToTrack(
        rooms: rooms,
        maxRooms: 6,
        activeLiveKey: 'room-a',
      );
      expect(keys, ['room-b']);
    });

    test('alias match skips discover SSE', () {
      expect(
        VoiceRoomDiscoverSsePolicy.shouldSkipRoom(
          roomKey: 'slug-x',
          roomEntityId: 'cuid-x',
          activeLiveKey: 'room-main',
          activeAliases: {'slug-x', 'room-main'},
        ),
        isTrue,
      );
    });

    test('no active key tracks up to maxRooms', () {
      final rooms = List.generate(
        8,
        (i) => VoiceRoomEntity(id: 'k-$i', slug: 's-$i', nameTr: 'R$i'),
      );
      final keys = VoiceRoomDiscoverSsePolicy.roomKeysToTrack(
        rooms: rooms,
        maxRooms: 6,
      );
      expect(keys, hasLength(6));
      expect(keys.first, 'k-0');
    });
  });
}
