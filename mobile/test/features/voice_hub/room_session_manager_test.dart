import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/presentation/coordinators/room_session_manager.dart';

void main() {
  group('RoomSessionManager', () {
    late RoomSessionManager manager;

    setUp(() {
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async => Future.value(),
        onLeavePresence: () async => Future.value(),
        onHeartbeat: () async => Future.value(),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Initial state is idle', () {
      expect(manager.state, RoomSessionState.idle);
      expect(manager.presence, isEmpty);
      expect(manager.seats, isEmpty);
    });

    test('Join transition: idle → joining → joined', () async {
      final states = <RoomSessionState>[];
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          states.add(event.current);
        }
      });

      await manager.join(onError: (_) {});

      expect(states, [RoomSessionState.joining, RoomSessionState.joined]);
      expect(manager.state, RoomSessionState.joined);
    });

    test('Join is idempotent — concurrent calls are blocked', () async {
      final joinCalls = <int>[];
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async {
          joinCalls.add(1);
          await Future.delayed(const Duration(milliseconds: 50));
        },
        onLeavePresence: () async {},
        onHeartbeat: () async {},
      );

      // Concurrent joins
      await Future.wait([
        manager.join(onError: (_) {}),
        manager.join(onError: (_) {}),
        manager.join(onError: (_) {}),
      ]);

      // Only one actual API call
      expect(joinCalls, hasLength(1));
      expect(manager.state, RoomSessionState.joined);
    });

    test('Leave from joined state', () async {
      final states = <RoomSessionState>[];
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          states.add(event.current);
        }
      });

      await manager.join(onError: (_) {});
      states.clear(); // Reset for leave test

      await manager.leave(onError: (_) {});

      expect(states, [RoomSessionState.leaving, RoomSessionState.idle]);
      expect(manager.state, RoomSessionState.idle);
    });

    test('Leave is idempotent — multiple calls safe', () async {
      final leaveCalls = <int>[];
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async {},
        onLeavePresence: () async {
          leaveCalls.add(1);
          await Future.delayed(const Duration(milliseconds: 50));
        },
        onHeartbeat: () async {},
      );

      await manager.join(onError: (_) {});

      // Multiple leaves
      await Future.wait([
        manager.leave(onError: (_) {}),
        manager.leave(onError: (_) {}),
      ]);

      // Only one actual API call
      expect(leaveCalls, hasLength(1));
      expect(manager.state, RoomSessionState.idle);
    });

    test('Network offline: joined → reconnecting', () async {
      final states = <RoomSessionState>[];
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          states.add(event.current);
        }
      });

      await manager.join(onError: (_) {});
      states.clear();

      manager.onNetworkStateChanged(false);

      expect(manager.state, RoomSessionState.reconnecting);
      expect(states, contains(RoomSessionState.reconnecting));
    });

    test('Presence update from SSE', () async {
      final updates = <RoomPresenceUpdated>[];
      manager.events.listen((event) {
        if (event is RoomPresenceUpdated) {
          updates.add(event);
        }
      });

      await manager.join(onError: (_) {});

      manager.applyServerEvent(
        eventType: 'presence_joined',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(
            id: 'user-1',
            name: 'User 1',
            seatIndex: 1,
          ),
          ChatRoomPresence(
            id: 'user-2',
            name: 'User 2',
            seatIndex: 2,
          ),
        ],
      );

      expect(updates, hasLength(1));
      expect(manager.presence, hasLength(2));
      expect(manager.presence[0].id, 'user-1');
    });

    test('Leave clears canonical state', () async {
      await manager.join(onError: (_) {});

      manager.applyServerEvent(
        eventType: 'presence_joined',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'User 1'),
        ],
      );

      expect(manager.presence, isNotEmpty);

      await manager.leave(onError: (_) {});

      expect(manager.presence, isEmpty);
      expect(manager.seats, isEmpty);
    });

    test('Failed join triggers reconnect backoff', () async {
      var attemptCount = 0;
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async {
          attemptCount++;
          throw Exception('Network error');
        },
        onLeavePresence: () async {},
        onHeartbeat: () async {},
      );

      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.failed);
      expect(attemptCount, 1);

      // Reconnect scheduled but not yet executed
      expect(manager.state, RoomSessionState.failed);
    });
  });
}
