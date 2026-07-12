import 'package:canlifal_social/core/auth/staff_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaffRoles', () {
    test('site admin is only username admin by default', () {
      expect(StaffRoles.isSiteAdminUser(username: 'admin'), isTrue);
      expect(StaffRoles.isSiteAdminUser(username: 'yonetici'), isFalse);
      expect(StaffRoles.isSiteAdminUser(role: 'yonetici'), isFalse);
      expect(StaffRoles.isSiteAdminUser(role: 'founder'), isTrue);
    });

    test('labelTr maps admin and yonetici display names', () {
      expect(StaffRoles.labelTr('admin'), 'Site Admin');
      expect(StaffRoles.labelTr('yonetici'), 'Kurucu');
      expect(StaffRoles.labelTr('founder'), 'Kurucu');
    });
  });
}
