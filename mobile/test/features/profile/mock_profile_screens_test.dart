import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/core/widgets/mock_ui_kit.dart';
import 'package:canlifal_social/features/admin/presentation/providers/staff_access_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/profile/presentation/pages/settings_category_page.dart';
import 'package:canlifal_social/features/profile/presentation/pages/settings_page.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/admin_profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.dark(), home: child),
    );

void main() {
  testWidgets('Ayarlar: 14 kategori satırı, arama süzer', (tester) async {
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const SettingsPage()));
    await tester.pump();
    expect(find.byType(MockListRow), findsNWidgets(settingsCategories.length));
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'bildirim');
    await tester.pump();
    expect(find.byType(MockListRow), findsOneWidget);
    expect(find.text('Bildirimler'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('Sonuç bulunamadı'), findsOneWidget);
  });

  testWidgets('Admin profil başlığı yalnızca yetkilide çizilir', (tester) async {
    const user = UserEntity(id: 'u', username: 'admin1');
    await tester.pumpWidget(
      _app(
        const Scaffold(body: SingleChildScrollView(child: AdminProfileHeader(user: user))),
        overrides: [staffAccessProvider.overrideWithValue(const StaffAccess(
          canManagePayments: false,
          isSiteAdmin: false,
          showAdminPanel: false,
          canManageGifts: false,
          canManageSiteAnimations: false,
          isStaffMember: false,
          canModerate: false,
          canManageVoiceRooms: false,
          canManageLiveStreams: false,
          canManageUsers: false,
          canViewReports: false,
          canManageNotifications: false,
          isSupportStaff: false,
          canViewActivityLog: false,
        ))],
      ),
    );
    expect(find.text('ADMIN'), findsNothing);
    expect(find.text('Yönetim Merkezi'), findsNothing);
  });
}
