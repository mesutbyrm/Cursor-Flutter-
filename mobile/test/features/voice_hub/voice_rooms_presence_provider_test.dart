import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    test('patchRoomCount updates local counts map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(
            'room-a',
            12,
          );

      expect(
        container.read(voiceRoomsPresenceProvider).counts['room-a'],
        12,
      );
    });

    test('an explicit server count is authoritative, zero included', () {
      expect(
        VoiceRoomsPresenceNotifier.parseOnlineCount({'onlineUsers': 7}),
        7,
      );
      expect(
        VoiceRoomsPresenceNotifier.parseOnlineCount({'onlineCount': 0}),
        0,
      );
    });

    test('a non-empty user list is counted', () {
      expect(
        VoiceRoomsPresenceNotifier.parseOnlineCount({
          'users': [
            {'id': 'a'},
            {'id': 'b'},
          ],
        }),
        2,
      );
    });

    test('an empty user list does not zero a populated room', () {
      expect(
        VoiceRoomsPresenceNotifier.parseOnlineCount({'users': <dynamic>[]}),
        isNull,
        reason: 'a seatless/empty snapshot must leave the previous count alone',
      );
      expect(
        VoiceRoomsPresenceNotifier.parseOnlineCount({'presence': <dynamic>[]}),
        isNull,
      );
    });

    test('an empty list still yields zero when the server also states it', () {
      expect(
        VoiceRoomsPresenceNotifier.parseOnlineCount({
          'onlineUsers': 0,
          'users': <dynamic>[],
        }),
        0,
      );
    });

    test('payload without any count signal returns null', () {
      expect(
        VoiceRoomsPresenceNotifier.parseOnlineCount({'userId': 'x'}),
        isNull,
      );
    });

    test('homeTrackedRooms is lower than maxTrackedRooms', () {
      expect(
        VoiceRoomsPresenceNotifier.homeTrackedRooms,
        lessThan(VoiceRoomsPresenceNotifier.maxTrackedRooms),
      );
    });
  });
}
