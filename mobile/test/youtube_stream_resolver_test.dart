import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/data/youtube_stream_resolver.dart';

void main() {
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
