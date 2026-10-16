import 'package:canlifal_social/core/auth/staff_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web yönetim sayfaları: sitedeki rollerle aynı', () {
    for (final r in ['admin', 'yonetici', 'kurucu', 'moderator', 'finans', 'ajans_admin', 'destek', 'icerik_moderator']) {
      expect(StaffRoles.canOpenWebAdmin(role: r), isTrue, reason: r);
    }
    expect(StaffRoles.canOpenWebAdmin(role: 'user'), isFalse);
    expect(StaffRoles.canOpenWebAdmin(role: 'teller'), isFalse);
    expect(StaffRoles.canOpenWebAdmin(role: null), isFalse);
    expect(StaffRoles.canOpenWebAdmin(role: 'user', walletIsAdmin: true), isTrue);
  });
}
