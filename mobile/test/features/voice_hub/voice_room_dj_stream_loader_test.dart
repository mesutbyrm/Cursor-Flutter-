import 'dart:io';

import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_room_dj_stream_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomDjStreamLoader', () {
    const cdn =
        'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1';

    test('clientPlaybackUrl rewrites googlevideo on Android only', () {
      final proxied = VoiceRoomDjStreamLoader.clientPlaybackUrl(cdn);
      if (Platform.isAndroid) {
        expect(proxied, contains('/api/chat/youtube-audio'));
        expect(proxied, contains('url='));
      } else {
        expect(proxied, cdn);
      }
    });

    test('buildPlaybackTargets adds proxy first on Android', () async {
      final loader = VoiceRoomDjStreamLoader(Dio());
      final targets = await loader.buildPlaybackTargets(cdn);
      expect(targets, isNotEmpty);
      if (Platform.isAndroid) {
        expect(targets.first, contains('/api/chat/youtube-audio'));
        expect(targets, contains(cdn));
      } else {
        expect(targets.first, cdn);
      }
    });
  });
}
