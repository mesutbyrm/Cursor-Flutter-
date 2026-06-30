import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/music/domain/entities/room_playback_sync.dart';

void main() {
  group('RoomPlaybackSync embed SSE', () {
    test('parses elapsedSeconds and videoId from dj payload', () {
      final sync = RoomPlaybackSync.fromPayload({
        'playing': true,
        'videoId': 'SsSR_vF2zaA',
        'elapsedSeconds': 42,
        'startedAtMs': 1710000000000,
        'embedUrl': 'https://www.youtube.com/embed/SsSR_vF2zaA',
        'nowPlaying': {
          'videoId': 'SsSR_vF2zaA',
          'title': 'Tarkan - Dudu',
        },
      });

      expect(sync.currentVideoId, 'SsSR_vF2zaA');
      expect(sync.elapsedSeconds, 42);
      expect(sync.resolvedStartSeconds(), 42);
      expect(sync.embedUrl, contains('embed'));
    });
  });
}
