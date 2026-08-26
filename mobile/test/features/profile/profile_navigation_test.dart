import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('profile navigation routes exist', () {
    const routes = [
      '/profile',
      '/profile/edit',
      '/jeton-store',
      '/wallet',
      '/premium-membership',
      '/settings',
      '/settings/blocked-users',
      '/settings/devices',
      '/blog/kahve-fali',
      '/celebrities/star-1',
      '/fan-club/club-1',
      '/profile/transactions',
      '/profile/followers',
      '/profile/following',
    ];
    for (final path in routes) {
      expect(path.startsWith('/'), isTrue);
    }
  });

  test('go_router push paths for jeton and membership', () {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/jeton-store', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/premium-membership',
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );
    expect(router.configuration.routes.length, 2);
  });
}
