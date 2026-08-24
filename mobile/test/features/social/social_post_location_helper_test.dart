import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_post_location_helper.dart';

void main() {
  test('formatSocialPostLocationSnippet prefixes pin emoji', () {
    expect(
      formatSocialPostLocationSnippet('İstanbul'),
      '📍 İstanbul',
    );
  });
}
