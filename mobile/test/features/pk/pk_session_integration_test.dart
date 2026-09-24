import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/presentation/coordinators/room_session_manager.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_seat_slot.dart';

void main() {
  group('PK Session Manager Integration', () {
    late RoomSessionManager manager;
    final eventLog = <String>[];

    setUp(() {
      eventLog.clear();
      manager = RoomSessionManager(
        roomId: 'test-room-123',
        userId: 'test-user-456',
        onJoinPresence: () async {
          eventLog.add('api.join');
          await Future.delayed(const Duration(milliseconds: 50));
        },
        onLeavePresence: () async {
          eventLog.add('api.leave');
          await Future.delayed(const Duration(milliseconds: 50));
        },
        onHeartbeat: () async {
          eventLog.add('api.heartbeat');
        },
      );

      // Log all manager events
      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          eventLog.add('room.state.${event.current}');
        } else if (event is RoomPresenceUpdated) {
          eventLog.add('room.presence.${event.source}');
        }
      });
    });

    tearDown(() {
      manager.dispose();
    });

    test('PK invite blocked when room not joined', () async {
      // Room in idle state — no presence
      expect(manager.state, RoomSessionState.idle);
      expect(manager.presence, isEmpty);

      // PK invite check would fail (room not joined)
      final isReady = manager.state == RoomSessionState.joined;
      expect(isReady, false);
    });

    test('PK invite allowed when room joined', () async {
      // Join room
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      // Now invite is allowed
      final isReady = manager.state == RoomSessionState.joined;
      expect(isReady, true);
    });

    test('PK battle invalidated when room disconnected', () async {
      // Start room session
      await manager.join(onError: (_) {});
      expect(manager.state, RoomSessionState.joined);

      eventLog.clear();

      // Simulate opponent user joining
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'opponent-user-789', name: 'Opponent'),
        ],
      );

      expect(manager.presence, hasLength(1));
      expect(eventLog, contains('room.presence.sse_presence'));

      eventLog.clear();

      // Room goes to leaving state (user left)
      await manager.leave(onError: (_) {});
      expect(manager.state, RoomSessionState.idle);
      expect(manager.presence, isEmpty);

      // PK battle should be invalidated (room left)
      expect(eventLog, contains('room.state.leaving'));
      expect(eventLog, contains('room.state.idle'));
    });

    test('PK opponent presence check during active match', () async {
      // Join room
      await manager.join(onError: (_) {});

      // Opponent joins
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'opponent-user-789', name: 'Opponent'),
        ],
      );

      expect(manager.presence, hasLength(1));
      expect(
        manager.presence.any((p) => p.id == 'opponent-user-789'),
        true,
      );

      eventLog.clear();

      // Opponent leaves during match
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [], // Empty presence
      );

      expect(manager.presence, isEmpty);

      // PK match would be invalidated (opponent left)
      expect(manager.presence.any((p) => p.id == 'opponent-user-789'), false);
    });

    test('PK state recovery after SSE reconnect', () async {
      // Start active PK session
      await manager.join(onError: (_) {});

      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'opponent-user-789', name: 'Opponent'),
        ],
      );

      expect(manager.state, RoomSessionState.joined);
      expect(manager.presence, hasLength(1));

      eventLog.clear();

      // Network outage
      manager.onNetworkStateChanged(false);
      expect(manager.state, RoomSessionState.reconnecting);

      eventLog.clear();

      // SSE reconnects
      manager.applyServerEvent(
        eventType: 'sse_connected',
        payload: {},
      );

      expect(manager.state, RoomSessionState.joined);

      // Opponent still present
      expect(manager.presence, hasLength(1));
      expect(
        manager.presence.any((p) => p.id == 'opponent-user-789'),
        true,
      );
    });

    test('Multiple users presence with PK check', () async {
      await manager.join(onError: (_) {});

      // Multiple users join
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'User 1'),
          ChatRoomPresence(id: 'user-2', name: 'User 2'),
          ChatRoomPresence(id: 'user-3', name: 'User 3'),
        ],
      );

      expect(manager.presence, hasLength(3));

      // Check specific opponent
      final opponentExists = manager.presence
          .any((p) => p.id == 'user-2');
      expect(opponentExists, true);

      eventLog.clear();

      // One user leaves
      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'user-1', name: 'User 1'),
          ChatRoomPresence(id: 'user-3', name: 'User 3'),
        ],
      );

      expect(manager.presence, hasLength(2));
      expect(
        manager.presence.any((p) => p.id == 'user-2'),
        false,
      );
    });

    test('PK recovery from heartbeat failure', () async {
      var heartbeatCount = 0;
      manager = RoomSessionManager(
        roomId: 'test-room-123',
        userId: 'test-user-456',
        onJoinPresence: () async => eventLog.add('api.join'),
        onLeavePresence: () async => eventLog.add('api.leave'),
        onHeartbeat: () async {
          heartbeatCount++;
          if (heartbeatCount == 1) {
            throw Exception('Heartbeat timeout');
          }
          eventLog.add('api.heartbeat.ok');
        },
      );

      manager.events.listen((event) {
        if (event is RoomSessionStateChanged) {
          eventLog.add('state.${event.current}');
        }
      });

      // Join and add opponent
      await manager.join(onError: (_) {});

      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'opponent-789', name: 'Opponent'),
        ],
      );

      expect(manager.presence, hasLength(1));

      eventLog.clear();

      // Heartbeat fails
      await manager.heartbeat(onError: (_) {});
      expect(manager.state, RoomSessionState.reconnecting);

      // Presence still maintained during reconnect
      expect(manager.presence, hasLength(1));

      // SSE reconnect
      manager.applyServerEvent(
        eventType: 'sse_connected',
        payload: {},
      );

      expect(manager.state, RoomSessionState.joined);
      // Opponent still there
      expect(manager.presence, hasLength(1));
    });

    test('PK session isolation between rooms', () async {
      // First room manager
      await manager.join(onError: (_) {});

      manager.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'room1-opponent', name: 'Room1 Opponent'),
        ],
      );

      expect(manager.presence, hasLength(1));
      expect(
        manager.presence[0].id,
        'room1-opponent',
      );

      // Create second room manager (isolated)
      final manager2 = RoomSessionManager(
        roomId: 'test-room-456',
        userId: 'test-user-456',
        onJoinPresence: () async {},
        onLeavePresence: () async {},
        onHeartbeat: () async {},
      );

      await manager2.join(onError: (_) {});

      manager2.applyServerEvent(
        eventType: 'sse_presence',
        payload: {},
        presenceUpdate: [
          ChatRoomPresence(id: 'room2-opponent', name: 'Room2 Opponent'),
        ],
      );

      // Managers are isolated
      expect(manager.presence, hasLength(1));
      expect(manager2.presence, hasLength(1));
      expect(manager.presence[0].id, 'room1-opponent');
      expect(manager2.presence[0].id, 'room2-opponent');

      manager2.dispose();
    });
  });
}
