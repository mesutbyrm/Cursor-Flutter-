import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_feed_refresh.dart';

void main() {
  group('buildSocialActiveRoomsEmbeddedTitle', () {
    test('voice only', () {
      expect(
        buildSocialActiveRoomsEmbeddedTitle(hasLive: false, hasVoice: true),
        'Sesli sohbet odaları',
      );
    });

    test('live only', () {
      expect(
        buildSocialActiveRoomsEmbeddedTitle(hasLive: true, hasVoice: false),
        'Canlı yayınlar',
      );
    });

    test('live and voice', () {
      expect(
        buildSocialActiveRoomsEmbeddedTitle(hasLive: true, hasVoice: true),
        'Canlı yayın ve sesli odalar',
      );
    });
  });
}
