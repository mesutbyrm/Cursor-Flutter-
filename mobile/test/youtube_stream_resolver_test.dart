import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/data/youtube_stream_resolver.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_dj_state.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/music_queue_item.dart';

void main() {
  group('ChatRoomDjState playback', () {
    test('playbackResolveSeed prefers nowPlaying youtube', () {
      final dj = ChatRoomDjState(
        musicUrl: 'https://rr1---sn.googlevideo.com/videoplayback?id=old',
        nowPlaying: MusicQueueItem(
          id: 'new',
          title: 'New Song',
          youtubeUrl: 'https://www.youtube.com/watch?v=NEWVIDEO12',
          createdAt: DateTime(2026),
        ),
        playing: true,
      );
      expect(
        dj.playbackResolveSeed,
        'https://www.youtube.com/watch?v=NEWVIDEO12',
      );
    });
  });

  group('YoutubeStreamResolver static checks', () {
    test('rejects YouTube watch URLs as direct streams', () {
      const watch = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      expect(YoutubeStreamResolver.isYoutubePageUrl(watch), isTrue);
      expect(YoutubeStreamResolver.isDirectAudioStreamUrl(watch), isFalse);
      expect(YoutubeStreamResolver.isDirectPlayableUrl(watch), isFalse);
    });

    test('accepts googlevideo as direct stream', () {
      const cdn =
          'https://rr3---sn-abc.googlevideo.com/videoplayback?mime=audio/mp4';
      expect(YoutubeStreamResolver.isYoutubePageUrl(cdn), isFalse);
      expect(YoutubeStreamResolver.isDirectAudioStreamUrl(cdn), isTrue);
    });

    test('wrapForMobilePlayback keeps googlevideo for local download', () {
      const cdn = 'https://x.googlevideo.com/videoplayback?id=1';
      expect(
        YoutubeStreamResolver.wrapForMobilePlayback(cdn),
        cdn,
      );
    });
  });
}
