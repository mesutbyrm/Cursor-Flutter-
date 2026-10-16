import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/admin/presentation/navigation/admin_nav.dart';
import 'package:canlifal_social/features/admin/presentation/pages/admin_management_center_page.dart';
import 'package:canlifal_social/features/admin/presentation/providers/staff_access_provider.dart';
import 'package:canlifal_social/features/admin_web/presentation/providers/admin_web_access_provider.dart';
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

Widget _app(Widget child, StaffAccess a, {bool web = false}) => ProviderScope(
      overrides: [
        staffAccessProvider.overrideWithValue(a),
        adminWebAccessProvider.overrideWithValue(web),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: child),
    );

List<String> _labels(StaffAccess a, {required bool web}) => [
      for (final g in visibleAdminNav(a, webAccess: web))
        for (final i in g.items) i.$1.label,
    ];

void main() {
  test('gruplar web yönetim paneliyle aynı sırada, başlık tekrarı yok', () {
    final titles = adminNavGroups(_access(admin: true)).map((g) => g.title).toList();
    expect(titles, [
      'Genel',
      'Profil & Kullanıcı',
      'Sesli Odalar',
      'Canlı Yayın',
      'Sosyal & İçerik',
      'Keşif & Analitik',
      'Ajans & Falcı',
      'Finans & Jeton',
      'Hediye & Ödül',
      'Animasyon & Görünüm',
      'Sistem & Yönetim',
    ]);
    expect(titles.toSet().length, titles.length);
  });

  test('her işlev tek yerde: aynı ad veya aynı hedef iki kez yok', () {
    final a = _access(admin: true);
    final labels = _labels(a, web: true);
    expect(labels.toSet().length, labels.length);
    final targets = [
      for (final g in visibleAdminNav(a, webAccess: true))
        for (final i in g.items)
          i.$2.route != null
              ? 'rota:${i.$2.route}'
              : i.$2.webPath != null
                  ? 'web:${i.$2.webPath}'
                  : 'islem:${i.$2.action}',
    ];
    expect(targets.toSet().length, targets.length);
  });

  test('çalışmayan / eski ekranlar menüde yok', () {
    final a = _access(admin: true);
    final routes = {
      for (final g in visibleAdminNav(a, webAccess: false))
        for (final i in g.items)
          if (i.$2.route != null) i.$2.route!,
    };
    expect(routes.intersection(adminRetiredPaths), isEmpty);
  });

  test('yetkiye göre görünürlük', () {
    expect(visibleAdminNav(_access(), webAccess: false), isEmpty);
    final mod = _labels(_access(moderate: true, reports: true), web: false);
    expect(mod, containsAll(['PK Moderasyonu', 'Şikayet Yönetimi']));
    expect(mod, isNot(contains('Kullanıcı Yönetimi')));
    expect(mod, isNot(contains('Hediye Kataloğu')));
    // Web paneli erişimi olmayan yetkili web sayfalarını görmez.
    expect(mod, isNot(contains('Blog Yönetimi')));
    final admin = _labels(_access(admin: true), web: true);
    expect(
      admin,
      containsAll([
        'Ödeme Talepleri (Jeton & CFC)',
        'Hediye Kataloğu',
        'Çekim & Ödüller',
        'Jeton Yönetimi',
        'GirLive Bot Yönetimi',
      ]),
    );
  });

  test('web tercihli madde: web erişimi yoksa yerel ekran', () {
    final a = _access(admin: true);
    final finans = adminNavGroups(a)
        .expand((g) => g.items)
        .firstWhere((i) => i.label == 'Finans Yönetimi');
    expect(finans.resolve(webAccess: true)!.webPath, '/admin/finance');
    expect(finans.resolve(webAccess: false)!.route, '/admin/finance-summary');
  });

  testWidgets('yetkisiz kullanıcı Yönetim Paneli göremez', (tester) async {
    await tester.pumpWidget(_app(const AdminManagementCenterPage(), _access()));
    await tester.pumpAndSettle();
    expect(find.text('Bu alan için yetkiniz yok.'), findsOneWidget);
    expect(find.text('Kullanıcı Yönetimi'), findsNothing);
  });

  testWidgets('arama süzer', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(const AdminManagementCenterPage(), _access(moderate: true, reports: true)),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'şikayet');
    await tester.pump();
    expect(find.text('Şikayet Yönetimi'), findsOneWidget);
    expect(find.text('PK Moderasyonu'), findsNothing);
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
