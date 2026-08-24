import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/entities/live_stream_entity.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_feed_layout.dart';

void main() {
  group('SocialFeedLayout', () {
    test('itemCount inserts room strip every two posts', () {
      expect(SocialFeedLayout.itemCount(1), 1);
      expect(SocialFeedLayout.itemCount(2), 3);
      expect(SocialFeedLayout.itemCount(4), 6);
    });

    test('itemCount without room strips returns post count only', () {
      expect(SocialFeedLayout.itemCount(4, includeRoomStrips: false), 4);
    });

    test('postIndexAt returns null for room strip slots', () {
      expect(SocialFeedLayout.postIndexAt(2, 4), isNull);
    });

    test('postIndexAt without room strips maps directly', () {
      expect(SocialFeedLayout.postIndexAt(2, 4, includeRoomStrips: false), 2);
    });
  });

  group('socialActiveRoomsAvailable', () {
    test('false when no live streams or voice rooms', () {
      expect(socialActiveRoomsAvailable(streams: const [], rooms: const []),
          isFalse);
    });

    test('true when live stream is active', () {
      expect(
        socialActiveRoomsAvailable(
          streams: [
            LiveStreamEntity(
              id: 's1',
              title: 'Test',
              isLive: true,
            ),
          ],
          rooms: const [],
        ),
        isTrue,
      );
    });

    test('true when voice rooms exist', () {
      expect(
        socialActiveRoomsAvailable(
          streams: const [],
          rooms: const [
            VoiceRoomEntity(id: 'r1', slug: 'oda', nameTr: 'Oda'),
          ],
        ),
        isTrue,
      );
    });
  });
}
