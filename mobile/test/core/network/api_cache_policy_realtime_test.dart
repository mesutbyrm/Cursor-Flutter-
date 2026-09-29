import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/network/api_cache_policy.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/data/mappers/voice_rooms_discover_mapper.dart';
import 'package:canlifal_social/features/voice_hub/domain/repositories/voice_rooms_discover_repository.dart';

bool _cacheable(String path) =>
    ApiCachePolicy.isCacheable(RequestOptions(path: path, method: 'GET'));

void main() {
  group('ApiCachePolicy gerçek zamanlı uçlar', () {
    test('PK / oda durumu / koltuk uçları önbelleğe alınmaz', () {
      expect(_cacheable('/api/chat/rooms/r1/pk'), isFalse);
      expect(_cacheable('/api/live/pk'), isFalse);
      expect(_cacheable('/api/video-streams/pk'), isFalse);
      expect(_cacheable('/api/chat/rooms/r1/state'), isFalse);
      expect(_cacheable('/api/chat/rooms/r1/sync'), isFalse);
      expect(_cacheable('/api/chat/rooms/r1/seats'), isFalse);
      expect(_cacheable('/api/chat/rooms/r1/speak-request'), isFalse);
    });

    test('oda listesi önbelleğe alınabilir', () {
      expect(_cacheable('/api/chat/rooms'), isTrue);
    });
  });

  group('Yakındaki odalar', () {
    test('boş odalar keşfette gösterilmez', () {
      final items = VoiceRoomsDiscoverMapper.nearbyFromRooms(
        const [
          VoiceRoomEntity(id: 'empty', slug: 'empty', nameTr: 'Boş'),
          VoiceRoomEntity(
            id: 'full',
            slug: 'full',
            nameTr: 'Dolu',
            onlineCount: 4,
            userCount: 4,
          ),
        ],
        tab: VoiceRoomsNearbyTab.nearby,
      );
      expect(items.map((e) => e.id), ['full']);
    });
  });
}
