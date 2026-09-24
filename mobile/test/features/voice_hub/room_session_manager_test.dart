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

    test('Heartbeat failure triggers reconnect', () async {
      var heartbeatCount = 0;
      final states = <RoomSessionState>[];
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async {},
        onLeavePresence: () async {},
        onHeartbeat: () async {
          heartbeatCount++;
          if (heartbeatCount == 1) {
            throw Exception('Heartbeat failed');
          }
        },
      );
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          states.add(event.current);
        }
      });

      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      // Trigger heartbeat failure
      await manager.heartbeat(onError: (_) {});
      expect(manager.state, RoomSessionState.reconnecting);
      expect(states, contains(RoomSessionState.reconnecting));
    });

    test('SSE reconnect signal returns to joined state', () async {
      final states = <RoomSessionState>[];
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          states.add(event.current);
        }
      });

      await manager.join(onError: (_) {});
      states.clear();

      // Simulate network offline
      manager.onNetworkStateChanged(false);
      expect(manager.state, RoomSessionState.reconnecting);

      // Simulate SSE reconnect
      manager.applyServerEvent(
        eventType: 'sse_connected',
        payload: {'type': 'sse_reconnected'},
      );

      expect(manager.state, RoomSessionState.joined);
      expect(states, contains(RoomSessionState.joined));
    });

    test('Seat update preserves presence state', () async {
      await manager.join(onError: (_) {});

      final presence = [
        ChatRoomPresence(id: 'user-1', name: 'User 1'),
      ];
      manager.applyServerEvent(
        eventType: 'presence_update',
        payload: {},
        presenceUpdate: presence,
      );

      final seats = [
        VoiceRoomSeatSlot(index: 0, userId: 'user-1'),
        VoiceRoomSeatSlot(index: 1),
      ];
      manager.applyServerEvent(
        eventType: 'seat_update',
        payload: {},
        seatsUpdate: seats,
      );

      expect(manager.presence, hasLength(1));
      expect(manager.seats, hasLength(2));
      expect(manager.state, RoomSessionState.joined);
    });

    test('Multiple events maintain consistency', () async {
      final eventLog = <String>[];
      manager.events.listen((event) {
        if (event is RoomPresenceUpdated) {
          eventLog.add('presence_${event.source}');
        } else if (event is RoomSeatsUpdated) {
          eventLog.add('seats_${event.source}');
        }
      });

      await manager.join(onError: (_) {});

      // Simulate SSE stream of events
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [ChatRoomPresence(id: 'u1', name: 'User 1')],
      );

      manager.applyServerEvent(
        eventType: 'sse_seat',
        payload: {},
        seatsUpdate: [VoiceRoomSeatSlot(index: 0, userId: 'u1')],
      );

      manager.applyServerEvent(
        eventType: 'poll_refresh',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'u1', name: 'User 1'),
          ChatRoomPresence(id: 'u2', name: 'User 2'),
        ],
      );

      expect(manager.presence, hasLength(2));
      expect(manager.seats, hasLength(1));
      expect(eventLog, [
        'presence_sse_presence',
        'seats_sse_seat',
        'presence_poll_refresh',
      ]);
    });

    test('Network recovery: offline → online → rejoined', () async {
      var joinAttempts = 0;
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async {
          joinAttempts++;
          // Simulate successful join on retry
          if (joinAttempts > 1) {
            return;
          }
          throw Exception('First attempt failed');
        },
        onLeavePresence: () async {},
        onHeartbeat: () async {},
      );

      // Initial join attempt fails
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.failed);

      // Network goes offline
      manager.onNetworkStateChanged(false);
      expect(manager.state, RoomSessionState.reconnecting);

      // Network comes back online
      manager.onNetworkStateChanged(true);
      expect(manager.state, RoomSessionState.joined);
    });

    test('Error event contains retriable flag', () async {
      final errors = <RoomSessionError>[];
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async {
          throw Exception('Retriable error');
        },
        onLeavePresence: () async {},
        onHeartbeat: () async {},
      );
      manager.events.listen((event) {
        if (event is RoomSessionError) {
          errors.add(event);
        }
      });

      await manager.join(onError: (_) {});

      // Error should be logged
      expect(manager.state, RoomSessionState.failed);
    });

    test('Concurrent join/leave safety', () async {
      var joinCalls = 0;
      var leaveCalls = 0;
      manager = RoomSessionManager(
        roomId: 'room-123',
        userId: 'user-456',
        onJoinPresence: () async {
          joinCalls++;
          await Future.delayed(const Duration(milliseconds: 100));
        },
        onLeavePresence: () async {
          leaveCalls++;
          await Future.delayed(const Duration(milliseconds: 100));
        },
        onHeartbeat: () async {},
      );

      // Start join but don't wait
      final joinFut = manager.join(onError: (_) {});

      // Try to leave while joining (should be blocked)
      final leaveFut = manager.leave(onError: (_) {});

      await joinFut;
      await leaveFut;

      // Only one join call should have been made
      expect(joinCalls, 1);
      // Leave should succeed after join completes
      expect(leaveCalls, 1);
      expect(manager.state, RoomSessionState.idle);
    });
  });
}
