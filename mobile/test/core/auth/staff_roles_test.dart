import 'package:canlifal_social/core/auth/staff_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaffRoles', () {
    test('site admin includes admin and yonetici', () {
      expect(StaffRoles.isSiteAdminUser(username: 'admin'), isTrue);
      expect(StaffRoles.isSiteAdminUser(username: 'yonetici'), isTrue);
      expect(StaffRoles.isSiteAdminUser(role: 'yonetici'), isTrue);
      expect(StaffRoles.isSiteAdminUser(role: 'founder'), isTrue);
      expect(StaffRoles.isSiteAdminUser(role: 'user'), isFalse);
    });

    test('labelTr maps admin and yonetici display names', () {
      expect(StaffRoles.labelTr('admin'), 'Site Admin');
      expect(StaffRoles.labelTr('yonetici'), 'Kurucu');
      expect(StaffRoles.labelTr('founder'), 'Kurucu');
    });
  });
}
