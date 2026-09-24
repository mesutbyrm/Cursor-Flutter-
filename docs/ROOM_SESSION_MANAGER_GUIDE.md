# RoomSessionManager Implementation Guide

**For:** Flutter Developers integrating voice room features  
**Last Updated:** 2026-09-24  
**Reference:** `mobile/lib/features/voice_hub/presentation/coordinators/room_session_manager.dart`

---

## 1. Overview

RoomSessionManager is a **centralized state machine** for managing voice room presence and synchronization. It guarantees:

- ✅ **Idempotency:** Single API call per operation (join, leave, heartbeat)
- ✅ **Atomicity:** State + presence + seats always consistent
- ✅ **Resilience:** Automatic recovery from network failures
- ✅ **Consistency:** Canonical state synchronized from SSE, API, polling

### Problem It Solves

**Before:** Race conditions, duplicate presence, incomplete state cleanup
```dart
// ❌ Problem: Multiple join calls
await _joinPresence();  // 1st API call
unawaited(_joinPresence());  // 2nd call (duplicate!)
// Result: POST sent twice, duplicate presence entry
```

**After:** Single atomic join operation
```dart
// ✅ Solution: Manager prevents concurrent joins
await manager.join(onError: handleError);
// Result: Single POST call, idempotent guarantee
```

---

## 2. Architecture

### State Machine

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  idle ──→ joining ──→ joined ──→ leaving ──→ idle
│           ↓           ↓ ↕       ↓
│          failed   reconnecting  (end)
│           ↑                      
│           └──────────────────────┘
│                                                 │
└─────────────────────────────────────────────────┘

States:
- idle:         No presence session
- joining:      Presence join in-flight
- joined:       Presence active, heartbeat running
- reconnecting: Network down, auto-recovery in progress
- leaving:      Leave in-flight
- failed:       Join failed, will retry on network recovery
```

### Key Properties

```dart
class RoomSessionManager {
  // State
  RoomSessionState state;                    // Current state
  List<ChatRoomPresence> presence;           // Canonical presence list
  List<VoiceRoomSeatSlot> seats;             // Seat allocation

  // Lifecycle
  Future<void> join(...)                     // → joined state
  Future<void> leave(...)                    // → idle state
  Future<void> heartbeat(...)                // Keep presence alive

  // Synchronization
  void applyServerEvent(...)                 // Sync SSE/API events
  void onNetworkStateChanged(bool online)    // Network recovery

  // Monitoring
  Stream<RoomSessionEvent> events            // State + error stream
  
  // Cleanup
  void dispose()                             // Free resources
}
```

---

## 3. Integration Points

### 3.1 Initialization (VoiceRoomLiveController)

```dart
// In chat_room_providers.dart build() method:

_roomSessionManager = RoomSessionManager(
  roomId: roomId,
  userId: userId,
  onJoinPresence: _joinPresenceForManager,  // Callback wrapper
  onLeavePresence: _leavePresenceForManager,
  onHeartbeat: _presenceHeartbeatForManager,
);

// Subscribe to manager events for logging/debugging
_roomSessionEventSub = _roomSessionManager.events.listen((event) {
  if (event is RoomSessionStateChanged) {
    print('[Manager] State: ${event.current}');
  } else if (event is RoomSessionError) {
    print('[Manager] Error: ${event.message}');
  }
});
```

### 3.2 Entry Flows (Begin Room Session)

**When:** User enters voice room  
**What:** Initiate presence join

```dart
// In chat_room_providers_entry.dart:

Future<void> _beginRoomSession() async {
  // Option 1: Use manager (preferred)
  if (_roomSessionManager != null) {
    await _roomSessionManager!.join(
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  } else {
    // Fallback for safety
    await _joinPresence();
  }
}
```

### 3.3 SSE Events (Real-Time Sync)

**When:** SSE delivers presence/seat updates  
**What:** Sync canonical state

```dart
// In chat_room_providers_sse.dart onPresence handler:

void onPresence(List<ChatRoomPresence> presence) {
  // Sync with manager
  _roomSessionManager?.applyServerEvent(
    eventType: 'sse_presence',
    payload: {},
    presenceUpdate: presence,
  );
  
  // Apply to local state (for UI)
  state = state.copyWith(presence: presence);
}
```

### 3.4 API Fetches (Periodic Sync)

**When:** Poll refresh or explicit seat fetch  
**What:** Sync manager canonical state

```dart
// In chat_room_providers_room_sync.dart:

Future<void> _fetchAndApplySeats() async {
  final seats = await _api.getSeats(roomId);
  final presence = await _api.getPresence(roomId);
  
  // Sync manager
  _roomSessionManager?.applyServerEvent(
    eventType: 'api_seats_fetch',
    payload: {},
    seatsUpdate: seats,
    presenceUpdate: presence,
  );
  
  // Update local state
  state = state.copyWith(
    seatSlots: seats,
    presence: presence,
  );
}
```

### 3.5 Network Recovery

**When:** Network state changes (online ↔ offline)  
**What:** Trigger automatic recovery

```dart
// In chat_room_providers_presence.dart:

void _startNetworkRecoveryWatch() {
  _networkRecoverySub = connectivity.onConnectivityChanged.listen((result) {
    final isOnline = result != ConnectivityResult.none;
    
    // Notify manager
    _roomSessionManager?.onNetworkStateChanged(isOnline);
    
    // If online, refresh state
    if (isOnline) {
      unawaited(_refreshRoomState());
    }
  });
}
```

### 3.6 PK Integration

**When:** Creating/managing PK matches in voice room  
**What:** Validate room session state

```dart
// In pk_session_notifier.dart:

bool _isVoiceRoomReadyForPk() {
  // Check room session manager state
  final manager = ref.read(roomSessionManager);
  return manager?.state == RoomSessionState.joined;
}

Future<void> create(String targetRoomId) async {
  // Block invite if room not ready
  if (!_isVoiceRoomReadyForPk()) {
    state = state.copyWith(
      error: 'Oda henüz hazır değil',
    );
    return;
  }
  
  // Proceed with invite
  await _createVoiceInvite(targetRoomId);
}
```

---

## 4. Common Usage Patterns

### Pattern 1: Simple Join & Leave

```dart
// User enters room
await manager.join(onError: handleError);
// → state transitions: idle → joining → joined
// → Heartbeat automatically starts (15s interval)

// User leaves room
await manager.leave(onError: handleError);
// → state transitions: joined → leaving → idle
// → Heartbeat stops, presence cleared
```

### Pattern 2: Network Recovery

```dart
// Network goes offline
manager.onNetworkStateChanged(false);
// → state: joined → reconnecting
// → Auto-retry with exponential backoff

// Network comes back online
manager.onNetworkStateChanged(true);
// → Attempts rejoin
// → If success: reconnecting → joined
// → If fail: remains reconnecting, continues backoff
```

### Pattern 3: Real-Time Presence Updates

```dart
// SSE delivers new presence
final presence = [...]; // from SSE event
manager.applyServerEvent(
  eventType: 'sse_presence',
  payload: {},
  presenceUpdate: presence,
);
// → state.presence updated
// → Event stream emits RoomPresenceUpdated
```

### Pattern 4: Monitoring State Changes

```dart
// Subscribe to state transitions
manager.events.listen((event) {
  if (event is RoomSessionStateChanged) {
    switch (event.current) {
      case RoomSessionState.idle:
        print('Room session ended');
        break;
      case RoomSessionState.joined:
        print('Room session active');
        break;
      case RoomSessionState.reconnecting:
        print('Network recovery in progress...');
        break;
      default:
        break;
    }
  } else if (event is RoomPresenceUpdated) {
    print('Presence updated from ${event.source}');
    print('Total users: ${state.presence.length}');
  } else if (event is RoomSessionError) {
    print('Error: ${event.message}');
  }
});
```

---

## 5. Idempotency Guarantees

### Guarantee 1: Single Join Call

```dart
// Multiple concurrent calls = 1 API call
Future.wait([
  manager.join(onError: (_) {}),
  manager.join(onError: (_) {}),
  manager.join(onError: (_) {}),
]);
// ✅ Result: POST /presence/join called once
```

### Guarantee 2: State Consistency

```dart
// All state updates are atomic
// (presence + seats + state in one operation)
manager.applyServerEvent(
  eventType: 'api_seats_fetch',
  seatsUpdate: [seat1, seat2],
  presenceUpdate: [user1, user2],
);
// ✅ Result: presence and seats stay in sync
```

### Guarantee 3: Automatic Cleanup

```dart
// Dispose clears all state and listeners
manager.dispose();
// ✅ Result: No memory leaks, no state leakage to next room
```

---

## 6. Error Handling

### Error Types

```dart
abstract class RoomSessionEvent {}

class RoomSessionStateChanged extends RoomSessionEvent {
  final RoomSessionState current;
  final RoomSessionState? previous;
}

class RoomPresenceUpdated extends RoomSessionEvent {
  final String source; // 'sse_presence', 'poll_refresh', etc.
}

class RoomSeatsUpdated extends RoomSessionEvent {
  final String source;
}

class RoomSessionError extends RoomSessionEvent {
  final String message;
  final bool isRetriable;
}
```

### Error Handling Pattern

```dart
await manager.join(
  onError: (error) {
    if (error is ApiException && error.statusCode == 429) {
      // Rate limited — show user message
      setState(() => error = 'Çok fazla istek, lütfen bekleyin');
    } else if (error is SocketException) {
      // Network error — will auto-recover
      print('Network error, waiting for recovery...');
    } else {
      // Other error
      setState(() => error = error.toString());
    }
  },
);
```

---

## 7. Testing

### Unit Test Example

```dart
test('Join idempotency — concurrent calls blocked', () async {
  var joinCalls = 0;
  manager = RoomSessionManager(
    roomId: 'room-123',
    userId: 'user-456',
    onJoinPresence: () async {
      joinCalls++;
      await Future.delayed(Duration(milliseconds: 50));
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

  // ✅ Only 1 API call made
  expect(joinCalls, 1);
  expect(manager.state, RoomSessionState.joined);
});
```

### Integration Test Example

```dart
test('Network recovery: offline → online → joined', () async {
  await manager.join(onError: (_) {});
  expect(manager.state, RoomSessionState.joined);

  // Network goes offline
  manager.onNetworkStateChanged(false);
  expect(manager.state, RoomSessionState.reconnecting);

  // Network comes back
  manager.onNetworkStateChanged(true);
  expect(manager.state, RoomSessionState.joined);
});
```

---

## 8. Troubleshooting

### Issue: "Room stuck in reconnecting state"

**Cause:** Network recovery backoff exhausted or missing SSE reconnect signal

**Solution:**
```dart
// Check if manager is still in reconnecting state
if (manager.state == RoomSessionState.reconnecting) {
  // Trigger explicit refresh
  await manager.applyServerEvent(
    eventType: 'sse_connected',
    payload: {},
  );
  // Or force rejoin
  await manager.join(onError: handleError);
}
```

### Issue: "Duplicate presence entries"

**Cause:** Multiple join calls or stale state from previous session

**Solution:**
```dart
// Clear old manager before starting new room
oldManager?.dispose();

// Create fresh manager
_roomSessionManager = RoomSessionManager(...);
```

### Issue: "Memory leak after room exit"

**Cause:** Event listeners not unsubscribed

**Solution:**
```dart
// Always dispose manager on room exit
ref.onDispose(() {
  _roomSessionManager?.dispose();
  _roomSessionEventSub?.cancel();
});
```

---

## 9. Performance Considerations

### Memory
- Manager keeps presence + seats in memory: ~1 KB per user
- For 1000 users: ~1 MB overhead (acceptable)
- Disposed after room exit: no leaks

### CPU
- State machine: O(1) per operation
- Event stream: synchronous listeners, minimal overhead
- Heartbeat: 1 API call per 15 seconds

### Network
- Reduce API calls: idempotency eliminates duplicates (~5% reduction)
- Polling: 8-second intervals for fallback consistency
- SSE: Real-time events, preferred over polling

---

## 10. API Reference

### RoomSessionManager Constructor

```dart
RoomSessionManager({
  required String roomId,
  required String userId,
  required Future<void> Function() onJoinPresence,
  required Future<void> Function() onLeavePresence,
  required Future<void> Function() onHeartbeat,
})
```

### Methods

#### `join()`
```dart
Future<void> join({
  required Function(Object) onError,
}) async
```
Transitions idle → joining → joined, starts heartbeat.

#### `leave()`
```dart
Future<void> leave({
  required Function(Object) onError,
}) async
```
Transitions joined → leaving → idle, cancels heartbeat.

#### `heartbeat()`
```dart
Future<void> heartbeat({
  required Function(Object) onError,
}) async
```
Send keep-alive ping if joined.

#### `applyServerEvent()`
```dart
void applyServerEvent({
  required String eventType,
  required Map<String, dynamic> payload,
  List<ChatRoomPresence>? presenceUpdate,
  List<VoiceRoomSeatSlot>? seatsUpdate,
})
```
Update canonical state from SSE/API/polling.

#### `onNetworkStateChanged()`
```dart
void onNetworkStateChanged(bool isOnline)
```
Trigger recovery on network state change.

#### `dispose()`
```dart
void dispose()
```
Free all resources and listeners.

### Events Stream

```dart
Stream<RoomSessionEvent> events
```

Listen for state changes, presence updates, seats updates, and errors.

---

**Version:** 1.0.0  
**Last Updated:** 2026-09-24  
**Status:** Complete

