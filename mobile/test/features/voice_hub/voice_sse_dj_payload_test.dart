import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_sse_dj_payload.dart';

void main() {
  group('unwrapVoiceSseDjPayload', () {
    test('flattens nested data map', () {
      final flat = unwrapVoiceSseDjPayload({
        'type': 'dj',
        'data': {
          'playing': true,
          'musicUrl': 'https://example.com/stream',
          'nowPlaying': {'videoId': 'abc', 'title': 'Test'},
        },
      });
      expect(flat['playing'], isTrue);
      expect(flat['musicUrl'], 'https://example.com/stream');
      expect(flat['nowPlaying'], isA<Map>());
    });

    test('voiceSseDjIsPlaying accepts isPlaying', () {
      expect(voiceSseDjIsPlaying({'isPlaying': true}), isTrue);
      expect(voiceSseDjIsPlaying({'playing': false}), isFalse);
    });

    test('voiceSseTrackStartedAtMs parses ISO', () {
      final ms = voiceSseTrackStartedAtMs('2025-06-25T12:00:00.000Z');
      expect(ms, isNotNull);
      expect(ms!, greaterThan(0));
    });
  });
}
