import 'package:canlifal_social/features/admin/presentation/providers/staff_access_provider.dart';
import 'package:canlifal_social/features/voice_hub/girlive/girlive_patron_address.dart';
import 'package:flutter_test/flutter_test.dart';

StaffAccess _staff({
  bool isSiteAdmin = false,
  bool isFounder = false,
  String? siteRole,
  String? username,
}) {
  return StaffAccess(
    canManagePayments: isSiteAdmin,
    isSiteAdmin: isSiteAdmin,
    showAdminPanel: isSiteAdmin,
    canManageGifts: false,
    canManageSiteAnimations: false,
    isStaffMember: isSiteAdmin || siteRole != null,
    canModerate: siteRole == 'moderator',
    canManageVoiceRooms: false,
    canManageLiveStreams: false,
    canManageUsers: false,
    canViewReports: false,
    canManageNotifications: false,
    isSupportStaff: false,
    canViewActivityLog: false,
    siteRole: siteRole,
    username: username,
    isFounder: isFounder,
  );
}

void main() {
  test('admin gets Patron salutation', () {
    final staff = _staff(isSiteAdmin: true, siteRole: 'admin');
    expect(
      GirLivePatronAddress.salutation(staff: staff, realName: 'Ali'),
      'Patron',
    );
  });

  test('yonetici gets Patron', () {
    final staff = _staff(siteRole: 'yonetici');
    expect(
      GirLivePatronAddress.qualifiesForPatron(staff: staff, siteRole: 'yonetici'),
      isTrue,
    );
  });

  test('Gold-like user without admin role is not Patron', () {
    final staff = _staff(siteRole: 'user', username: 'golduser');
    expect(GirLivePatronAddress.qualifiesForPatron(staff: staff), isFalse);
    expect(
      GirLivePatronAddress.salutation(
        staff: staff,
        realName: 'Ahmet',
        username: 'golduser',
      ),
      'Ahmet',
    );
  });

  test('moderator is not Patron', () {
    final staff = _staff(siteRole: 'moderator', username: 'mod1');
    expect(GirLivePatronAddress.qualifiesForPatron(staff: staff), isFalse);
  });

  test('display label falls back to username', () {
    expect(
      GirLivePatronAddress.resolveDisplayLabel(username: 'mehmet123'),
      '@mehmet123',
    );
  });
}
