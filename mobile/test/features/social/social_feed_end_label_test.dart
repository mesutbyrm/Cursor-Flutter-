import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_feed_end_label.dart';

void main() {
  test('socialFeedEndReachedLabel is stable', () {
    expect(socialFeedEndReachedLabel, 'Tüm paylaşımları gördün');
  });
}
