import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_post_detail_route.dart';

void main() {
  test('buildSocialPostDetailRoute trims and encodes post id', () {
    expect(
      buildSocialPostDetailRoute('  post/42  '),
      '/social/post/post%2F42',
    );
  });
}
