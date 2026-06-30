import 'package:canlifal_social/core/push/push_navigation_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('buffers tap payload until router is installed', () {
    PushNavigationHandler.handleNotificationTap({
      'type': 'message',
      'targetPath': '/messages',
      'title': 'Test',
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
        GoRoute(path: '/messages', builder: (_, __) => const SizedBox.shrink()),
      ],
    );

    PushNavigationHandler.install(router);
    expect(router.routeInformationProvider.value.uri.path, '/messages');
  });
}
