import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/auth/staff_roles.dart';

void main() {
  group('StaffRoles granular permissions', () {
    test('moderator can moderate but not manage finance by role alone', () {
      expect(
        StaffRoles.canModerateContent(role: 'moderator'),
        isTrue,
      );
      expect(
        StaffRoles.canManageFinance(role: 'moderator'),
        isFalse,
      );
    });

    test('admin can manage finance and users', () {
      expect(
        StaffRoles.canManageFinance(role: 'admin'),
        isTrue,
      );
      expect(
        StaffRoles.canManageUsers(role: 'admin'),
        isTrue,
      );
    });

    test('support role is staff but not finance', () {
      expect(StaffRoles.isSupportRole('destek'), isTrue);
      expect(StaffRoles.isAnyStaff(role: 'destek'), isTrue);
      expect(StaffRoles.canManageFinance(role: 'destek'), isFalse);
    });

    test('wallet canManagePayments enables finance', () {
      expect(
        StaffRoles.canManageFinance(
          role: 'user',
          walletCanManagePayments: true,
        ),
        isTrue,
      );
    });

    test('moderator can manage voice rooms and live streams', () {
      expect(
        StaffRoles.canManageVoiceRooms(role: 'moderator'),
        isTrue,
      );
      expect(
        StaffRoles.canManageLiveStreams(role: 'moderator'),
        isTrue,
      );
    });
  });
}
