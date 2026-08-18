import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_rooms_presence_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceRoomsPresenceNotifier', () {
    test('build starts with empty state and no connected rooms', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(voiceRoomsPresenceProvider);

      expect(state.counts, isEmpty);
      expect(state.connectedRooms, isEmpty);
    });

    test('mergeTrackRooms schedules tracked room keys', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rooms = [
        const VoiceRoomEntity(
          id: 'room-a',
          slug: 'room-a',
          nameTr: 'Oda A',
          ownerId: 'u1',
          ownerName: 'Host',
        ),
        const VoiceRoomEntity(
          id: 'room-b',
          slug: 'room-b',
          nameTr: 'Oda B',
          ownerId: 'u2',
          ownerName: 'Host 2',
        ),
      ];

      container
          .read(voiceRoomsPresenceProvider.notifier)
          .mergeTrackRooms(rooms);

      final state = container.read(voiceRoomsPresenceProvider);
      expect(state.connectedRooms, containsAll(['room-a', 'room-b']));
    });

    test('homeTrackedRooms is lower than maxTrackedRooms', () {
      expect(
        VoiceRoomsPresenceNotifier.homeTrackedRooms,
        lessThan(VoiceRoomsPresenceNotifier.maxTrackedRooms),
      );
    });
  });
}
