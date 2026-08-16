import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_feed_layout.dart';

void main() {
  group('SocialFeedLayout', () {
    test('itemCount inserts room strip every two posts', () {
      expect(SocialFeedLayout.itemCount(1), 1);
      expect(SocialFeedLayout.itemCount(2), 3);
      expect(SocialFeedLayout.itemCount(4), 6);
    });

    test('postIndexAt returns null for room strip slots', () {
      expect(SocialFeedLayout.postIndexAt(2, 4), isNull);
    });
  });
}
