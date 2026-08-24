import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_sse_dj_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeSongSseForDjPlayback maps song_started to playing dj payload', () {
    final normalized = normalizeSongSseForDjPlayback({
      'type': 'song_started',
      'currentSong': {
        'videoId': 'abc123',
        'title': 'Test',
        'musicUrl': 'https://example.com/stream',
        'withVideo': true,
      },
    });
    expect(normalized['playing'], isTrue);
    expect(normalized['nowPlaying'], isA<Map>());
    expect(normalized['musicUrl'], 'https://example.com/stream');
    expect(normalized['videoId'], 'abc123');
  });

  test('shouldApplyDjPlaybackFromSongSse includes song_started', () {
    expect(
      shouldApplyDjPlaybackFromSongSse({'type': 'song_started'}),
      isTrue,
    );
    expect(
      shouldApplyDjPlaybackFromSongSse({'type': 'message'}),
      isFalse,
    );
  });
}
