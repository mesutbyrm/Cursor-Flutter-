import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_room_dj_stream_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomDjStreamLoader', () {
    const cdn =
        'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1';

    test('clientPlaybackUrl keeps googlevideo URL on Android', () {
      final proxied = VoiceRoomDjStreamLoader.clientPlaybackUrl(cdn);
      expect(proxied, cdn);
    });

    test('buildPlaybackTargets prefers direct CDN on Android', () async {
      final loader = VoiceRoomDjStreamLoader(Dio());
      final targets = await loader.buildPlaybackTargets(cdn);
      expect(targets, isNotEmpty);
      expect(targets.first, cdn);
    });

    test('preparePlaybackSource keeps googlevideo on Android', () async {
      final loader = VoiceRoomDjStreamLoader(Dio());
      final prepared = await loader.preparePlaybackSource(cdn);
      expect(prepared, isNotNull);
      expect(prepared, cdn);
    });
  });
}
