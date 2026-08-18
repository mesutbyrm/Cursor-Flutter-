import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/music/data/datasources/room_music_remote_datasource.dart';
import 'package:dio/dio.dart';

void main() {
  group('RoomMusicRemoteDataSource queue response', () {
    test('extracts streamUrl from nested nowPlaying', () {
      final ds = RoomMusicRemoteDataSource(Dio());
      final parsed = ds.parseQueueResponseForTest({
        'playing': true,
        'nowPlaying': {
          'title': 'Test Song',
          'videoId': 'abc123',
          'musicUrl': 'https://canlifal.com/api/chat/youtube-audio?v=abc123',
        },
      });
      expect(parsed.streamUrl, contains('youtube-audio'));
      expect(parsed.playing, isTrue);
    });
  });
}
