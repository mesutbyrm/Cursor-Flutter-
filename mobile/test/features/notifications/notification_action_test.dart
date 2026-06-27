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
}
