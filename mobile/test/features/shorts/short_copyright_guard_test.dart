import 'package:canlifal_social/features/shorts/domain/utils/short_copyright_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShortCopyrightGuard', () {
    test('validatePublish allows catalog music', () {
      expect(
        ShortCopyrightGuard.validatePublish(
          musicId: 'track-1',
          voiceoverPath: null,
          muted: false,
        ),
        isNull,
      );
    });

    test('validateExternalAudio blocks custom path', () {
      expect(
        ShortCopyrightGuard.validateExternalAudio('/tmp/audio.mp3'),
        contains('Harici ses'),
      );
    });

    test('validateExternalAudio allows null', () {
      expect(ShortCopyrightGuard.validateExternalAudio(null), isNull);
    });
  });
}
