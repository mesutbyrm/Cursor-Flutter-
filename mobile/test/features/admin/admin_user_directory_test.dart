import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/admin/presentation/pages/admin_live_stats_page.dart';
import 'package:canlifal_social/features/admin/presentation/widgets/admin_user_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {double scale = 1}) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: Scaffold(body: child),
      ),
    );

void main() {
  test('filtre → sunucu parametreleri', () {
    expect(AdminUserFilter.active.segment, 'active');
    expect(AdminUserFilter.passive.segment, 'passive');
    expect(AdminUserFilter.admin.role, 'admin');
    expect(AdminUserFilter.broadcaster.adv, 'broadcasting');
    expect(AdminUserFilter.banned.clientBanned, isTrue);
  });

  test('ban ve çevrimiçi durumu yardımcıları', () {
    expect(adminUserIsBanned({'isBanned': true}), isTrue);
    expect(adminUserIsBanned({'isFrozen': true}), isTrue);
    expect(adminUserIsBanned({'role': 'user'}), isFalse);
    expect(
      adminUserIsOnline({'lastActiveAt': DateTime.now().toIso8601String()}),
      isTrue,
    );
    expect(
      adminUserIsOnline({
        'lastActiveAt':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      }),
      isFalse,
    );
    expect(adminUserIsOnline({}), isFalse);
  });

  testWidgets('kullanıcı satırı: uzun ad, büyük yazı, küçük ekranda taşmaz',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const AdminUserRow(
          user: {
            'id': 'u1',
            'username': 'cok_uzun_bir_kullanici_adi_ornegi_1234567890',
            'role': 'moderator',
            'membership': 'gold',
            'isBanned': true,
          },
        ),
        scale: 1.6,
      ),
    );
    expect(find.text('Banlı'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('Moderatör'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    for (final t in ['Profil', 'Ban / Unban', 'Mute', 'Rol', 'Şikâyetler', 'Aktiviteler']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('grafik: veri yokken sahte çizim yok, veri varken çizilir', (tester) async {
    await tester.pumpWidget(_app(const AdminSeriesChart(points: [])));
    expect(find.textContaining('henüz sağlanmıyor'), findsOneWidget);
    await tester.pumpWidget(
      _app(
        const AdminSeriesChart(
          points: [AdminSeriesPoint('a', 1), AdminSeriesPoint('b', 3), AdminSeriesPoint('c', 2)],
        ),
      ),
    );
    expect(find.textContaining('henüz sağlanmıyor'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
