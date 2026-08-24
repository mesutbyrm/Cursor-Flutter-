import 'package:canlifal_social/features/voice_hub/presentation/services/voice_room_dj_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomDjPlayer production resolve skip', () {
    test('skips youtube watch URL on production', () {
      expect(
        VoiceRoomDjPlayer.skipsStreamResolveOnProduction(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        isTrue,
      );
    });

    test('skips youtube-stream API URL on production', () {
      expect(
        VoiceRoomDjPlayer.skipsStreamResolveOnProduction(
          '/api/chat/youtube-stream?videoId=abc123',
        ),
        isTrue,
      );
    });

    test('does not skip direct googlevideo CDN', () {
      expect(
        VoiceRoomDjPlayer.skipsStreamResolveOnProduction(
          'https://rr1---sn-abc.googlevideo.com/videoplayback?id=foo',
        ),
        isFalse,
      );
    });
  });
}
