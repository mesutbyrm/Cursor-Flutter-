import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/music/domain/entities/room_playback_sync.dart';

void main() {
  test('RoomPlaybackSync resolves live position while playing', () {
    final started = DateTime.now().millisecondsSinceEpoch - 5000;
    final sync = RoomPlaybackSync(
      currentPositionMs: 10000,
      isPlaying: true,
      trackStartedAtMs: started,
    );
    final pos = sync.resolvedPositionMs();
    expect(pos, greaterThanOrEqualTo(14000));
    expect(pos, lessThan(20000));
  });

  test('RoomPlaybackSync.fromPayload reads server fields', () {
    final sync = RoomPlaybackSync.fromPayload({
      'currentVideoId': 'abc123',
      'currentPosition': 42,
      'playing': true,
      'trackStartedAt': 1000,
      'musicUrl': 'https://example.com/stream.m4a',
    });
    expect(sync.currentVideoId, 'abc123');
    expect(sync.currentPositionMs, 42);
    expect(sync.isPlaying, isTrue);
    expect(sync.streamUrl, 'https://example.com/stream.m4a');
  });
}
