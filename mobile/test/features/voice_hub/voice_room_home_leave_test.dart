import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/chat_room_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_session_registry.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_leave_flow.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_room/voice_room_route_presence_guard.dart';

final _leaveCalls = <String>[];

class _FakeLive extends VoiceRoomLiveController {
  @override
  VoiceRoomLiveState build(String roomKey) => const VoiceRoomLiveState();

  @override
  Future<void> leaveRoomSession({
    String source = 'ui_leave',
    bool awaitBackend = true,
    bool force = false,
  }) async {
    _leaveCalls.add('$arg:$source');
  }
}

Widget _page(String label) => Scaffold(body: Text(label));

GoRouter _router() => GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(path: '/feed', builder: (_, __) => _page('home')),
        GoRoute(path: '/voice-rooms', builder: (_, __) => _page('list')),
        GoRoute(
          path: '/voice-room/:id',
          builder: (_, s) => _page('room ${s.pathParameters['id']}'),
        ),
        GoRoute(path: '/profile/:id', builder: (_, __) => _page('profile')),
      ],
    );

Future<(GoRouter, ProviderContainer)> _pump(WidgetTester tester) async {
  final router = _router();
  final container = ProviderContainer(
    overrides: [
      goRouterProvider.overrideWithValue(router),
      voiceRoomLiveProvider.overrideWith(_FakeLive.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: VoiceRoomRoutePresenceGuard(
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, container);
}

void main() {
  setUp(_leaveCalls.clear);

  group('VoiceRoomLeaveFlow route kontrolü', () {
    test('ana sayfa ve oda listesi odadan çıkış sayılır', () {
      expect(VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute('/feed'), isFalse);
      expect(
        VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute('/voice-rooms'),
        isFalse,
      );
      expect(
        VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute('/voice-room/a'),
        isTrue,
      );
    });

    test('odanın üstüne açılan sayfa yığında odayı korur', () {
      expect(
        VoiceRoomLeaveFlow.voiceRoomInStack(['/profile/u', '/voice-room/a']),
        isTrue,
      );
      expect(VoiceRoomLeaveFlow.voiceRoomInStack(['/feed']), isFalse);
    });
  });

  group('VoiceRoomRoutePresenceGuard', () {
    testWidgets('Room → Home: tek leave', (tester) async {
      final (router, container) = await _pump(tester);
      router.go('/voice-room/a');
      await tester.pumpAndSettle();
      container.read(voiceRoomActiveLiveKeyProvider.notifier).state = 'a';

      router.go('/feed');
      await tester.pumpAndSettle();
      router.go('/voice-rooms');
      await tester.pumpAndSettle();

      expect(_leaveCalls, ['a:route_left_voice_room']);
    });

    testWidgets('Room A → Room B: guard leave göndermez', (tester) async {
      final (router, container) = await _pump(tester);
      router.go('/voice-room/a');
      await tester.pumpAndSettle();
      container.read(voiceRoomActiveLiveKeyProvider.notifier).state = 'a';

      router.go('/voice-room/b');
      await tester.pumpAndSettle();

      expect(_leaveCalls, isEmpty);
    });

    testWidgets('odanın üstüne profil push: leave yok', (tester) async {
      final (router, container) = await _pump(tester);
      router.go('/voice-room/a');
      await tester.pumpAndSettle();
      container.read(voiceRoomActiveLiveKeyProvider.notifier).state = 'a';

      router.push('/profile/u');
      await tester.pumpAndSettle();

      expect(_leaveCalls, isEmpty);
    });

    testWidgets('UI leave sonrası (aktif oda yok) çift leave yok',
        (tester) async {
      final (router, _) = await _pump(tester);
      router.go('/voice-room/a');
      await tester.pumpAndSettle();
      // UI leave aktif anahtarı temizledi → guard tekrar leave atmaz.
      router.go('/feed');
      await tester.pumpAndSettle();

      expect(_leaveCalls, isEmpty);
    });
  });
}
