import 'package:canlifal_social/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:canlifal_social/features/notifications/domain/notification_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('jeton_payment_request routes admin to /admin', (tester) async {
    late String? lastLocation;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, _) {
            lastLocation = '/admin';
            return const SizedBox.shrink();
          },
        ),
        GoRoute(
          path: '/jeton-store',
          builder: (_, _) {
            lastLocation = '/jeton-store';
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );

    navigateFromNotification(
      router,
      const AppNotificationEntity(
        id: '1',
        title: 'Jeton talebi',
        type: 'jeton_payment_request',
      ),
      staffCanManagePayments: true,
    );
    await tester.pumpAndSettle();

    expect(lastLocation, '/admin');
  });

  testWidgets('jeton_payment_request routes user to jeton store', (tester) async {
    late String? lastLocation;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/jeton-store',
          builder: (_, _) {
            lastLocation = '/jeton-store';
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );

    navigateFromNotification(
      router,
      const AppNotificationEntity(
        id: '1',
        title: 'Jeton talebi',
        type: 'jeton_payment_request',
      ),
    );
    await tester.pumpAndSettle();

    expect(lastLocation, '/jeton-store');
  });

  testWidgets('payment title routes to jeton store', (tester) async {
    late String? lastLocation;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/jeton-store',
          builder: (_, _) {
            lastLocation = '/jeton-store';
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );

    navigateFromNotification(
      router,
      const AppNotificationEntity(
        id: '1',
        title: 'Ödeme Onaylandı! ✅',
        body: '50 jeton hesabınıza eklendi.',
        type: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(lastLocation, '/jeton-store');
  });

  testWidgets('session title routes to canli falcilar', (tester) async {
    late String? lastLocation;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/canli-falcilar',
          builder: (_, _) {
            lastLocation = '/canli-falcilar';
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );

    navigateFromNotification(
      router,
      const AppNotificationEntity(
        id: '2',
        title: 'Randevu Kabul Edildi',
        body: 'Canlı sohbet odasına girebilirsiniz.',
      ),
    );
    await tester.pumpAndSettle();

    expect(lastLocation, '/canli-falcilar');
  });

  testWidgets('pk invite with root targetPath routes to voice room', (tester) async {
    late String? lastLocation;
    final router = GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(
          path: '/feed',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/voice-room/:id',
          builder: (_, state) {
            lastLocation = '/voice-room/${state.pathParameters['id']}';
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    navigateFromNotification(
      router,
      const AppNotificationEntity(
        id: 'pk1',
        title: 'PK Daveti',
        type: 'pk_invite',
        targetPath: '/',
        targetId: 'room-abc',
      ),
    );
    await tester.pumpAndSettle();

    expect(lastLocation, '/voice-room/room-abc');
  });

  testWidgets('root targetPath without type falls back to feed', (tester) async {
    late String? lastLocation;
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/feed',
          builder: (_, _) {
            lastLocation = '/feed';
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    navigateFromNotification(
      router,
      const AppNotificationEntity(
        id: 'x',
        title: 'Bildirim',
        targetPath: '/',
      ),
    );
    await tester.pumpAndSettle();

    expect(lastLocation, '/feed');
  });
}
