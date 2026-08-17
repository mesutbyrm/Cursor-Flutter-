import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_user_profile_route.dart';

void main() {
  test('buildSocialUserProfileRoute trims user id', () {
    expect(
      buildSocialUserProfileRoute('  u42  '),
      '/user/u42',
    );
  });
}
