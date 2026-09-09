import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/admin/domain/admin_user_detail.dart';

void main() {
  test('formatMembershipTenure formats years and months', () {
    final since = DateTime.now().subtract(const Duration(days: 400));
    final text = formatMembershipTenure(since);
    expect(text.contains('yıl') || text.contains('ay'), isTrue);
  });

  test('formatLastOnline shows online when flag set', () {
    expect(
      formatLastOnline(null, isOnline: true),
      'Şu an online',
    );
  });

  test('AdminUserDetail merges admin and public maps', () {
    final d = AdminUserDetail.fromMaps(
      userId: 'u1',
      admin: {'coins': 100, 'role': 'moderator'},
      publicProfile: {'username': 'test', 'followers': 5},
    );
    expect(d.jeton, 100);
    expect(d.username, 'test');
    expect(d.followers, 5);
    expect(d.role, 'moderator');
  });
}
