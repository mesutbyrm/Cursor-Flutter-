import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_room_dj_stream_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomDjStreamLoader', () {
    test('clientPlaybackUrl rewrites googlevideo to backend proxy on Android', () {
      const cdn =
          'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1';
      final proxied = VoiceRoomDjStreamLoader.clientPlaybackUrl(cdn);
      expect(proxied, contains('/api/chat/youtube-audio'));
      expect(proxied, contains('url='));
    });

    test('buildPlaybackTargets prefers backend proxy on Android', () async {
      const cdn =
          'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1';
      final loader = VoiceRoomDjStreamLoader(Dio());
      final targets = await loader.buildPlaybackTargets(cdn);
      expect(targets, isNotEmpty);
      expect(targets.first, contains('/api/chat/youtube-audio'));
      expect(targets, contains(cdn));
    });
  });
}
