import 'package:canlifal_social/core/auth/staff_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strict web admin allows admin role', () {
    expect(
      StaffRoles.isStrictWebAdmin(role: 'admin'),
      isTrue,
    );
  });

  test('strict web admin allows superadmin', () {
    expect(
      StaffRoles.isStrictWebAdmin(role: 'superadmin'),
      isTrue,
    );
  });

  test('strict web admin rejects moderator', () {
    expect(
      StaffRoles.isStrictWebAdmin(role: 'moderator'),
      isFalse,
    );
  });

  test('strict web admin rejects yonetici without wallet flag', () {
    expect(
      StaffRoles.isStrictWebAdmin(role: 'yonetici'),
      isFalse,
    );
  });
}
