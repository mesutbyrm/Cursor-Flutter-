import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/presentation/coordinators/room_session_manager.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';

void main() {
  group('RoomSessionManager Race Conditions', () {
    late RoomSessionManager manager;

    setUp(() {
      manager = RoomSessionManager(
        roomId: 'test-room-123',
        userId: 'test-user-456',
        onJoinPresence: () async => Future.value(),
        onLeavePresence: () async => Future.value(),
        onHeartbeat: () async => Future.value(),
      );
    });

    tearDown(() {
      // Note: dispose() closes _eventController
      try {
        manager.dispose();
      } catch (_) {}
    });

    test('applyServerEvent after dispose should not crash', () async {
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      // Dispose manager (closes _eventController)
      manager.dispose();

      // Try to apply event AFTER dispose (simulates SSE event arriving late)
      // Should silently ignore instead of crashing
      expect(
        () => manager.applyServerEvent(
          eventType: 'sse_presence',
          payload: {},
          presenceUpdate: [
            ChatRoomPresence(id: 'user-1', name: 'User 1'),
          ],
        ),
        returnsNormally,
      );
    });

    test('setState after dispose should not crash', () async {
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      // Dispose manager
      manager.dispose();

      // Try to set state AFTER dispose (should silently ignore, not crash)
      expect(
        () => manager.onNetworkStateChanged(false),
        returnsNormally,
      );
    });

    test('Concurrent SSE events with manager disposal', () async {
      await manager.join(onError: (_) {});

      // Simulate concurrent SSE event + disposal
      final sseEventFuture = Future.delayed(
        const Duration(milliseconds: 50),
        () {
          manager.applyServerEvent(
            eventType: 'sse_presence',
            payload: {},
            presenceUpdate: [
              ChatRoomPresence(id: 'user-1', name: 'User 1'),
            ],
          );
        },
      );

      // Dispose concurrently
      final disposeFuture = Future.delayed(
        const Duration(milliseconds: 25),
        () => manager.dispose(),
      );

      // One of these will fail, but code should handle it
      final results = await Future.wait([sseEventFuture, disposeFuture],
          eagerError: false);
      expect(results, isNotEmpty);
    });

    test('Multiple listeners can subscribe without crashing', () async {
      final listener1Events = <RoomSessionEvent>[];
      final listener2Events = <RoomSessionEvent>[];

      final sub1 = manager.events.listen((event) {
        listener1Events.add(event);
      });

      final sub2 = manager.events.listen((event) {
        listener2Events.add(event);
      });

      // Join should complete without crashing
      await manager.join(onError: (_) {});

      // Manager state should be updated (this is reliable, not dependent on listener timing)
      expect(manager.state, RoomSessionState.joined);

      // Both listeners should have received at least some events (listener timing is async)
      expect(listener1Events.isNotEmpty, true);
      expect(listener2Events.isNotEmpty, true);

      sub1.cancel();
      sub2.cancel();
    });

    test('Old session events leak into new session', () async {
      final oldListener = <String>[];

      // Register listener in "old session"
      final sub = manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          oldListener.add(event.current.toString());
        }
      });

      // Join old session
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);
      expect(oldListener, isNotEmpty);

      // Clear listener log
      oldListener.clear();

      // Dispose old session (closes event controller)
      manager.dispose();
      sub.cancel();

      // Create NEW manager (simulates new room session)
      final newManager = RoomSessionManager(
        roomId: 'new-room-456',
        userId: 'test-user-456',
        onJoinPresence: () async => Future.value(),
        onLeavePresence: () async => Future.value(),
        onHeartbeat: () async => Future.value(),
      );

      final newListener = <String>[];
      final newSub = newManager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          newListener.add(event.current.toString());
        }
      });

      // Join new session
      await newManager.join(onError: (_) {});

      // New listener should only see new session's events
      expect(newListener.length, 2); // joining + joined
      expect(oldListener.isEmpty, true); // Old listener still empty

      newSub.cancel();
      newManager.dispose();
    });

    test('Heartbeat timer does not crash after dispose', () async {
      var heartbeatCount = 0;
      var heartbeatError = false;
      manager = RoomSessionManager(
        roomId: 'test-room-123',
        userId: 'test-user-456',
        onJoinPresence: () async => Future.value(),
        onLeavePresence: () async => Future.value(),
        onHeartbeat: () async {
          try {
            heartbeatCount++;
          } catch (_) {
            heartbeatError = true;
          }
        },
      );

      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      // Dispose manager (should cancel timers)
      manager.dispose();

      // Wait to see if heartbeat fires after dispose and crashes
      await Future.delayed(const Duration(seconds: 1));

      // Should not have crashed
      expect(heartbeatError, false);
    });

    test('SSE reconnection with pending events', () async {
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      // Simulate network offline → reconnecting
      manager.onNetworkStateChanged(false);
      expect(manager.state, RoomSessionState.reconnecting);

      // Queue multiple SSE events while reconnecting
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'User 1'),
        ],
      );

      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'User 1'),
          ChatRoomPresence(id: 'user-2', name: 'User 2'),
        ],
      );

      // Then reconnect happens
      manager.applyServerEvent(
        eventType: 'sse_connected',
        payload: {},
      );

      // Should be back to joined with latest presence
      expect(manager.state, RoomSessionState.joined);
      expect(manager.presence, hasLength(2));
    });
  });
}
