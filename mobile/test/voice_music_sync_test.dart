import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/voice_music_sync.dart';

void main() {
  group('VoiceMusicSync.parseSongRequestFree', () {
    test('parses production free-request payload', () {
      const raw =
          '[SONG_REQUEST_FREE] -CxauCeQ_SQ|TARKAN - Kış Güneşi (Official Music Video)|||';
      final parsed = VoiceMusicSync.parseSongRequestFree(raw);
      expect(parsed, isNotNull);
      expect(parsed!.videoId, '-CxauCeQ_SQ');
      expect(parsed.title, contains('TARKAN'));
      expect(parsed.youtubeUrl, contains('-CxauCeQ_SQ'));
    });

    test('returns null for unrelated chat lines', () {
      expect(
        VoiceMusicSync.parseSongRequestFree('merhaba dünya'),
        isNull,
      );
    });
  });

  group('VoiceMusicSync.isQueueUpdateMessage', () {
    test('detects SONG_REQUEST_FREE lines', () {
      expect(
        VoiceMusicSync.isQueueUpdateMessage(
          '[SONG_REQUEST_FREE] abc|Title|||',
        ),
        isTrue,
      );
    });

    test('detects şarkı isteği gönderdi lines', () {
      expect(
        VoiceMusicSync.isQueueUpdateMessage(
          'Admin şarkı isteği gönderdi: TARKAN - Kış Güneşi',
        ),
        isTrue,
      );
    });
  });
}
