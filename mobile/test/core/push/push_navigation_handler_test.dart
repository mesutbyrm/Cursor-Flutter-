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

  test('navigateToPath maps root to feed', () {
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(path: '/notifications', builder: (_, __) => const SizedBox.shrink()),
        GoRoute(path: '/feed', builder: (_, __) => const SizedBox.shrink()),
      ],
    );
    PushNavigationHandler.install(router);
    PushNavigationHandler.navigateToPath('/');
    expect(router.routeInformationProvider.value.uri.path, '/feed');
  });

  test('navigateToPath maps /home and /index to feed', () {
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(path: '/notifications', builder: (_, __) => const SizedBox.shrink()),
        GoRoute(path: '/feed', builder: (_, __) => const SizedBox.shrink()),
      ],
    );
    PushNavigationHandler.install(router);
    PushNavigationHandler.navigateToPath('/home');
    expect(router.routeInformationProvider.value.uri.path, '/feed');
    PushNavigationHandler.navigateToPath('/index');
    expect(router.routeInformationProvider.value.uri.path, '/feed');
  });

  test('pk push tap with root path routes to voice room', () async {
    final prepared = <String>[];
    final router = GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(path: '/feed', builder: (_, __) => const SizedBox.shrink()),
        GoRoute(
          path: '/voice-room/:id',
          builder: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
    PushNavigationHandler.install(
      router,
      onPrepareVoiceRoomSwitch: (key, {source = 'push'}) async {
        prepared.add('$source:$key');
      },
    );
    await PushNavigationHandler.handleNotificationTap({
      'type': 'pk_invite',
      'targetPath': '/',
      'targetId': 'room-xyz',
      'title': 'PK Daveti',
    });
    expect(router.routeInformationProvider.value.uri.path, '/voice-room/room-xyz');
    expect(prepared, ['notification:room-xyz']);
  });
}
