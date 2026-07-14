import 'package:canlifal_social/core/auth/staff_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaffRoles', () {
    test('founder staff is yonetici only', () {
      expect(StaffRoles.isFounderUser(username: 'admin'), isFalse);
      expect(StaffRoles.isFounderUser(username: 'yonetici'), isTrue);
      expect(StaffRoles.isFounderUser(role: 'yonetici'), isTrue);
      expect(StaffRoles.isFounderUser(role: 'founder'), isTrue);
      expect(StaffRoles.isSiteAdminUser(username: 'yonetici'), isTrue);
      expect(StaffRoles.isSiteAdminUser(role: 'admin'), isTrue);
      expect(StaffRoles.isSiteAdminUser(role: 'user'), isFalse);
    });

    test('labelTr maps admin and yonetici display names', () {
      expect(StaffRoles.labelTr('admin'), 'Site Admin');
      expect(StaffRoles.labelTr('yonetici'), 'Kurucu');
      expect(StaffRoles.labelTr('founder'), 'Kurucu');
    });
  });
}
