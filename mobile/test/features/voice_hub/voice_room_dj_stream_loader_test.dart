import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_room_dj_stream_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomDjStreamLoader', () {
    test('clientPlaybackUrl keeps googlevideo direct', () {
      const cdn =
          'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1';
      expect(VoiceRoomDjStreamLoader.clientPlaybackUrl(cdn), cdn);
    });

    test('buildPlaybackTargets prefers direct CDN on Android', () async {
      const cdn =
          'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1';
      final loader = VoiceRoomDjStreamLoader(Dio());
      final targets = await loader.buildPlaybackTargets(cdn);
      expect(targets, isNotEmpty);
      expect(targets.first, cdn);
      if (targets.length > 1) {
        expect(
          targets.last,
          contains('/api/chat/youtube-audio'),
        );
      }
    });
  });
}
