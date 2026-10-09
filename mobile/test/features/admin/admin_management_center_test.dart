import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/admin/presentation/pages/admin_management_center_page.dart';
import 'package:canlifal_social/features/admin/presentation/providers/staff_access_provider.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/widgets/profile_management_center_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

StaffAccess _access({
  bool admin = false,
  bool moderate = false,
  bool reports = false,
  bool users = false,
}) =>
    StaffAccess(
      canManagePayments: admin,
      isSiteAdmin: admin,
      showAdminPanel: admin,
      canManageGifts: admin,
      canManageSiteAnimations: admin,
      isStaffMember: admin || moderate,
      canModerate: moderate || admin,
      canManageVoiceRooms: admin,
      canManageLiveStreams: admin,
      canManageUsers: users || admin,
      canViewReports: reports || admin,
      canManageNotifications: admin,
      isSupportStaff: false,
      canViewActivityLog: admin,
    );

Widget _app(Widget child, StaffAccess a) => ProviderScope(
      overrides: [staffAccessProvider.overrideWithValue(a)],
      child: MaterialApp(theme: AppTheme.dark(), home: child),
    );

void main() {
  test('kart görünürlüğü yetkiye bağlı', () {
    expect(adminCenterEntries(_access()).where((e) => e.visible), isEmpty);
    final mod = adminCenterEntries(_access(moderate: true, reports: true))
        .where((e) => e.visible)
        .map((e) => e.title)
        .toSet();
    expect(mod, containsAll(['PK Yönetimi', 'Şikayetler']));
    expect(mod.contains('Kullanıcı Yönetimi'), isFalse);
    expect(mod.contains('Sistem Ayarları'), isFalse);
    expect(mod.contains('Acil Durum'), isFalse);
    expect(mod.contains('Sosyal Medya'), isFalse);
    expect(adminCenterEntries(_access(admin: true)).where((e) => e.visible).length, 11);
  });

  testWidgets('yetkisiz kullanıcı Yönetim Merkezi göremez', (tester) async {
    await tester.pumpWidget(_app(const AdminManagementCenterPage(), _access()));
    await tester.pumpAndSettle();
    expect(find.text('Bu alan için yetkiniz yok.'), findsOneWidget);
    expect(find.text('Kullanıcı Yönetimi'), findsNothing);
  });

  testWidgets('admin: 11 kart küçük ekranda 2 kolon, taşma yok', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const AdminManagementCenterPage(), _access(admin: true)));
    await tester.pumpAndSettle();
    expect(find.text('Kullanıcı Yönetimi'), findsOneWidget);
    expect(find.text('Acil Durum'), findsOneWidget);
    final a = tester.getTopLeft(find.text('Kullanıcı Yönetimi'));
    final b = tester.getTopLeft(find.text('Canlı Yayın Yönetimi'));
    expect(b.dx, greaterThan(a.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('YÖNETİM MERKEZİ düğmesi yalnızca yetkilide görünür', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: ProfileManagementCenterButton()), _access()));
    expect(find.text('YÖNETİM MERKEZİ'), findsNothing);
    await tester.pumpWidget(
      _app(const Scaffold(body: ProfileManagementCenterButton()), _access(admin: true)),
    );
    expect(find.text('YÖNETİM MERKEZİ'), findsOneWidget);
  });
}
