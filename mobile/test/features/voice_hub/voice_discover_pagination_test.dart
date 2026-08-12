import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/repositories/voice_rooms_discover_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discover bundle carries API pagination metadata', () {
    const bundle = VoiceRoomsDiscoverBundle(
      categories: [],
      featured: [],
      popular: [],
      allRooms: [
        VoiceRoomEntity(
          id: 'r1',
          slug: 'r1',
          nameTr: 'Oda',
          category: 'music',
        ),
      ],
      apiPage: 2,
      apiHasMore: true,
    );

    expect(bundle.apiPage, 2);
    expect(bundle.apiHasMore, isTrue);
    expect(bundle.allRooms.single.category, 'music');
  });
}
