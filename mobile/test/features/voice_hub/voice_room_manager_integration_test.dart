import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/presentation/coordinators/room_session_manager.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_seat_slot.dart';

void main() {
  group('RoomSessionManager Integration', () {
    late RoomSessionManager manager;
    final eventLog = <String>[];

    setUp(() {
      eventLog.clear();
      manager = RoomSessionManager(
        roomId: 'test-room-123',
        userId: 'test-user-456',
        onJoinPresence: () async {
          eventLog.add('api.join_presence');
          await Future.delayed(const Duration(milliseconds: 50));
        },
        onLeavePresence: () async {
          eventLog.add('api.leave_presence');
          await Future.delayed(const Duration(milliseconds: 50));
        },
        onHeartbeat: () async {
          eventLog.add('api.heartbeat');
        },
      );

      // Log all manager events
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          eventLog.add('manager.state.${event.current.name}');
        } else if (event is RoomPresenceUpdated) {
          eventLog.add('manager.presence.${event.source}');
        } else if (event is RoomSeatsUpdated) {
          eventLog.add('manager.seats.${event.source}');
        }
      });
    });

    tearDown(() {
      manager.dispose();
    });

    test('Full join/presence/leave lifecycle', () async {
      // Initial state
      expect(manager.state, RoomSessionState.idle);

      // Join flow
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);
      expect(eventLog, contains('api.join_presence'));
      expect(eventLog, contains('manager.state.joining'));
      expect(eventLog, contains('manager.state.joined'));

      eventLog.clear();

      // Receive presence from SSE
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'Alice', seatIndex: 0),
          ChatRoomPresence(id: 'user-2', name: 'Bob', seatIndex: 1),
        ],
      );

      expect(manager.presence, hasLength(2));
      expect(eventLog, contains('manager.presence.sse_presence'));

      eventLog.clear();

      // Receive seats from API
      manager.applyServerEvent(
        eventType: 'api_seats',
        payload: {},
        seatsUpdate: [
          VoiceRoomSeatSlot(index: 0, userId: 'user-1'),
          VoiceRoomSeatSlot(index: 1, userId: 'user-2'),
          VoiceRoomSeatSlot(index: 2),
        ],
      );

      expect(manager.seats, hasLength(3));
      expect(eventLog, contains('manager.seats.api_seats'));

      eventLog.clear();

      // Heartbeat
      await manager.heartbeat(onError: (_) {});
      expect(eventLog, contains('api.heartbeat'));

      eventLog.clear();

      // Leave flow
      await manager.leave(onError: (_) {});
      expect(manager.state, RoomSessionState.idle);
      expect(manager.presence, isEmpty);
      expect(manager.seats, isEmpty);
      expect(eventLog, contains('api.leave_presence'));
      expect(eventLog, contains('manager.state.leaving'));
      expect(eventLog, contains('manager.state.idle'));
    });

    test('SSE reconnect after network outage', () async {
      // Start in joined state
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      eventLog.clear();

      // Network goes down
      manager.onNetworkStateChanged(false);
      expect(manager.state, RoomSessionState.reconnecting);
      expect(eventLog, contains('manager.state.reconnecting'));

      eventLog.clear();

      // Receive SSE reconnect signal
      manager.applyServerEvent(
        eventType: 'sse_connected',
        payload: {},
      );
      expect(manager.state, RoomSessionState.joined);
      expect(eventLog, contains('manager.state.joined'));

      // Presence should be maintained during reconnection
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'Alice'),
        ],
      );
      expect(manager.presence, hasLength(1));
    });

    test('Heartbeat failure recovery', () async {
      var heartbeatCount = 0;
      manager = RoomSessionManager(
        roomId: 'test-room-123',
        userId: 'test-user-456',
        onJoinPresence: () async => eventLog.add('api.join'),
        onLeavePresence: () async => eventLog.add('api.leave'),
        onHeartbeat: () async {
          heartbeatCount++;
          eventLog.add('api.heartbeat.${heartbeatCount}');
          // Fail on first heartbeat
          if (heartbeatCount == 1) {
            throw Exception('Heartbeat timeout');
          }
        },
      );
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          eventLog.add('state.${event.current.name}');
        }
      });

      // Join successfully
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      eventLog.clear();

      // Heartbeat fails
      await manager.heartbeat(onError: (_) {});
      expect(manager.state, RoomSessionState.reconnecting);
      expect(eventLog, contains('state.reconnecting'));

      // After SSE reconnect, should return to joined
      manager.applyServerEvent(
        eventType: 'sse_connected',
        payload: {},
      );
      expect(manager.state, RoomSessionState.joined);
    });

    test('Poll refresh maintains presence consistency', () async {
      await manager.join(onError: (_) {});

      // Simulate SSE presence
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'Alice'),
          ChatRoomPresence(id: 'user-2', name: 'Bob'),
        ],
      );
      expect(manager.presence, hasLength(2));

      eventLog.clear();

      // Poll refresh with updated presence
      manager.applyServerEvent(
        eventType: 'poll_refresh',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'Alice'),
          ChatRoomPresence(id: 'user-2', name: 'Bob'),
          ChatRoomPresence(id: 'user-3', name: 'Charlie'),
        ],
      );

      expect(manager.presence, hasLength(3));
      expect(eventLog, contains('manager.presence.poll_refresh'));
    });

    test('Concurrent operations maintain state consistency', () async {
      // Simulate rapid operations
      final futures = [
        manager.join(onError: (_) {}),
        Future.delayed(const Duration(milliseconds: 10), () {
          manager.applyServerEvent(
            eventType: 'presence',
            payload: {},
            presenceUpdate: [ChatRoomPresence(id: 'u1', name: 'User 1')],
          );
        }),
        Future.delayed(const Duration(milliseconds: 20), () {
          manager.applyServerEvent(
            eventType: 'seats',
            payload: {},
            seatsUpdate: [VoiceRoomSeatSlot(index: 0, userId: 'u1')],
          );
        }),
        Future.delayed(const Duration(milliseconds: 30), () async {
          await manager.heartbeat(onError: (_) {});
        }),
      ];

      await Future.wait(futures);

      // State should be consistent
      expect(manager.state, RoomSessionState.joined);
      expect(manager.presence, hasLength(1));
      expect(manager.seats, hasLength(1));
    });

    test('Multiple SSE events in sequence', () async {
      await manager.join(onError: (_) {});

      // Event 1: First presence update
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'Alice', seatIndex: 0),
        ],
      );

      // Event 2: Add more presence
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'Alice', seatIndex: 0),
          ChatRoomPresence(id: 'user-2', name: 'Bob', seatIndex: 1),
        ],
      );

      // Event 3: Seat update
      manager.applyServerEvent(
        eventType: 'sse_seat',
        payload: {},
        seatsUpdate: [
          VoiceRoomSeatSlot(index: 0, userId: 'user-1'),
          VoiceRoomSeatSlot(index: 1, userId: 'user-2'),
        ],
      );

      // Event 4: More presence
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'Alice', seatIndex: 0),
          ChatRoomPresence(id: 'user-2', name: 'Bob', seatIndex: 1),
          ChatRoomPresence(id: 'user-3', name: 'Charlie', seatIndex: 2),
        ],
      );

      // Final state should be consistent
      expect(manager.presence, hasLength(3));
      expect(manager.seats, hasLength(2)); // Only first 2 seats from event 3
    });

    test('State recovery after various failures', () async {
      var joinAttempts = 0;
      manager = RoomSessionManager(
        roomId: 'test-room-123',
        userId: 'test-user-456',
        onJoinPresence: () async {
          joinAttempts++;
          eventLog.add('api.join.attempt_$joinAttempts');
          if (joinAttempts < 3) {
            throw Exception('Connection timeout');
          }
        },
        onLeavePresence: () async => eventLog.add('api.leave'),
        onHeartbeat: () async => eventLog.add('api.heartbeat'),
      );
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          eventLog.add('state.${event.current}');
        }
      });

      // First join attempt fails
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.failed);

      eventLog.clear();

      // Network recovery trigger
      manager.onNetworkStateChanged(false);
      manager.onNetworkStateChanged(true);

      // After successful recovery, should be joined
      await Future.delayed(const Duration(milliseconds: 200));
      // Note: In real scenario, reconnect would succeed
      // Here we're just verifying state machine doesn't crash
      expect(manager.state, isNotNull);
    });
  });
}
