import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/music_queue_item.dart';
import 'package:canlifal_social/features/voice_hub/data/youtube_stream_resolver.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_dj_state.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/music_queue_item.dart';

void main() {
  group('ChatRoomDjState playback', () {
    test('playbackResolveSeed prefers nowPlaying youtube over server googlevideo', () {
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
      expect(dj.playbackSource, dj.playbackResolveSeed);
    });

    test('playbackSource ignores server googlevideo when only musicUrl set', () {
      final dj = ChatRoomDjState(
        musicUrl:
            'https://rr3---sn-abc.googlevideo.com/videoplayback?v=dQw4w9WgXcQ',
        playing: true,
      );
      expect(
        dj.playbackResolveSeed,
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
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

    test('wrapForMobilePlayback uses backend proxy on Android', () {
      const cdn = 'https://x.googlevideo.com/videoplayback?id=1';
      final wrapped = YoutubeStreamResolver.wrapForMobilePlayback(cdn);
      if (Platform.isAndroid) {
        expect(wrapped, contains('/api/chat/youtube-audio'));
      } else {
        expect(wrapped, cdn);
      }
    });

    test('detects youtube-stream API URL as needing resolve', () {
      const api =
          'https://canlifal.com/api/chat/youtube-stream?videoId=dQw4w9WgXcQ';
      expect(YoutubeStreamResolver.isYoutubeStreamApiUrl(api), isTrue);
      expect(YoutubeStreamResolver.needsResolveBeforePlay(api), isTrue);
      expect(YoutubeStreamResolver.isDirectPlayableUrl(api), isFalse);
    });

    test('videoIdFrom reads videoId query param on site API URL', () {
      final resolver = YoutubeStreamResolver(Dio());
      expect(
        resolver.videoIdFrom(
          'https://canlifal.com/api/chat/youtube-stream?videoId=dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
    });
  });

  group('MusicQueueItem video mode', () {
    test('asVideoRequest marks audio item as video request', () {
      final item = MusicQueueItem(
        id: '1',
        title: 'Test',
        youtubeUrl: 'https://www.youtube.com/watch?v=abc12345678',
        createdAt: DateTime(2026),
      );
      expect(item.isVideoRequest, isFalse);
      final video = item.asVideoRequest();
      expect(video.isVideoRequest, isTrue);
      expect(video.withVideo, isTrue);
      expect(video.requestType, 'video');
    });
  });
}
