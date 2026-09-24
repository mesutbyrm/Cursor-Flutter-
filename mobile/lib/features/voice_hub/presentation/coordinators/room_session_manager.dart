import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_seat_slot.dart';

/// Room session state machine durumları
enum RoomSessionState {
  idle,           // Kullanıcı hiçbir odada değil
  joining,        // Presence join işlemi devam ediyor
  joined,         // Presence aktif, heartbeat çalışıyor
  reconnecting,   // Bağlantı yeniden kuruluyor
  leaving,        // Odadan ayrılış işlemi devam ediyor
  failed,         // Giriş veya bağlantı başarısız
}

/// Room session yaşam döngüsü events
abstract class RoomSessionEvent {
  const RoomSessionEvent();
}

class RoomSessionStateChanged extends RoomSessionEvent {
  const RoomSessionStateChanged({
    required this.previous,
    required this.current,
    this.reason,
  });

  final RoomSessionState previous;
  final RoomSessionState current;
  final String? reason;
}

class RoomPresenceUpdated extends RoomSessionEvent {
  const RoomPresenceUpdated({
    required this.presence,
    required this.source,
  });

  final List<ChatRoomPresence> presence;
  final String source; // 'join', 'sse', 'poll', 'heartbeat'
}

class RoomSeatsUpdated extends RoomSessionEvent {
  const RoomSeatsUpdated({
    required this.seats,
    required this.source,
  });

  final List<VoiceRoomSeatSlot> seats;
  final String source;
}

class RoomSessionError extends RoomSessionEvent {
  const RoomSessionError({
    required this.message,
    this.code,
    this.retriable = true,
  });

  final String message;
  final String? code;
  final bool retriable;
}

/// Concurrency control — join/leave/reconnect operations
class _RoomSessionLock {
  var _locked = false;
  final List<Completer<void>> _waiters = [];

  Future<void> acquire() async {
    if (!_locked) {
      _locked = true;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _locked = true;
      final waiter = _waiters.removeAt(0);
      waiter.complete();
    } else {
      _locked = false;
    }
  }
}

/// Centralized room session manager — idempotency ve state consistency garantisi
class RoomSessionManager {
  RoomSessionManager({
    required this.roomId,
    required this.userId,
    this.onJoinPresence,
    this.onLeavePresence,
    this.onHeartbeat,
  });

  final String roomId;
  final String userId;

  /// API callbacks (set after initialization)
  Future<void> Function()? onJoinPresence;
  Future<void> Function()? onLeavePresence;
  Future<void> Function()? onHeartbeat;

  /// State machine
  late RoomSessionState _state = RoomSessionState.idle;
  Timer? _heartbeatTimer;
  Timer? _reconnectBackoffTimer;
  var _reconnectBackoffMs = 100;
  final _lock = _RoomSessionLock();

  /// Canonical state — source of truth
  var _canonicalPresence = <ChatRoomPresence>[];
  var _canonicalSeats = <VoiceRoomSeatSlot>[];
  final Set<String> _knownPresenceIds = {};

  /// Events
  final StreamController<RoomSessionEvent> _eventController =
      StreamController<RoomSessionEvent>.broadcast();

  Stream<RoomSessionEvent> get events => _eventController.stream;

  RoomSessionState get state => _state;

  List<ChatRoomPresence> get presence => List.unmodifiable(_canonicalPresence);

  List<VoiceRoomSeatSlot> get seats => List.unmodifiable(_canonicalSeats);

  /// Presence join — idempotent, concurrent calls bloke
  Future<void> join({
    required void Function(String reason) onError,
  }) async {
    await _lock.acquire();
    try {
      // Zaten joining/joined/reconnecting ise skip
      if (_state != RoomSessionState.idle &&
          _state != RoomSessionState.failed) {
        if (_state == RoomSessionState.joined) {
          return; // Already in room
        }
        // Anderen durumda zaten bir işlem var, çıkış yap
        return;
      }

      _setState(RoomSessionState.joining, 'User initiated join');

      try {
        await onJoinPresence?.call();
        _setState(RoomSessionState.joined, 'Presence joined successfully');
        _startHeartbeat();
        _reconnectBackoffMs = 100; // Reset backoff
      } on Object catch (e) {
        _setState(
          RoomSessionState.failed,
          'Join failed: ${e.toString()}',
        );
        onError(e.toString());
        // Retry ile backoff
        _scheduleReconnect();
      }
    } finally {
      _lock.release();
    }
  }

  /// Presence leave — idempotent
  Future<void> leave({
    required void Function(String reason) onError,
    bool force = false,
  }) async {
    await _lock.acquire();
    try {
      if (_state == RoomSessionState.idle || _state == RoomSessionState.leaving) {
        return; // Already left or leaving
      }

      _setState(RoomSessionState.leaving, 'User initiated leave');
      _cancelHeartbeat();
      _cancelReconnect();

      try {
        await onLeavePresence?.call();
      } on Object catch (e) {
        if (!force) {
          onError(e.toString());
          return;
        }
        // Force: ignore error
        debugPrint('Room leave error (forced): $e');
      }

      _setState(RoomSessionState.idle, 'Left successfully');
      _clearCanonicalState();
    } finally {
      _lock.release();
    }
  }

  /// Presence heartbeat — fail sırasında auto-retry
  Future<void> heartbeat({
    required void Function(String reason) onError,
  }) async {
    if (_state != RoomSessionState.joined &&
        _state != RoomSessionState.reconnecting) {
      return;
    }

    try {
      await onHeartbeat?.call();
    } on Object catch (e) {
      onError(e.toString());
      // Heartbeat fail → reconnect başlat
      if (_state == RoomSessionState.joined) {
        _setState(
          RoomSessionState.reconnecting,
          'Heartbeat failed: ${e.toString()}',
        );
        _scheduleReconnect();
      }
    }
  }

  /// SSE event — atomic presence + seat update
  void applyServerEvent({
    required String eventType,
    required Map<String, dynamic> payload,
    List<ChatRoomPresence>? presenceUpdate,
    List<VoiceRoomSeatSlot>? seatsUpdate,
  }) {
    if (_state == RoomSessionState.idle) return;

    // Canonical update
    if (presenceUpdate != null) {
      _canonicalPresence = presenceUpdate;
      _syncPresenceIds();
      _eventController.add(
        RoomPresenceUpdated(
          presence: List.unmodifiable(_canonicalPresence),
          source: eventType,
        ),
      );
    }

    if (seatsUpdate != null) {
      _canonicalSeats = seatsUpdate;
      _eventController.add(
        RoomSeatsUpdated(
          seats: List.unmodifiable(_canonicalSeats),
          source: eventType,
        ),
      );
    }

    // SSE reconnect success → joined state'e dön
    if (eventType == 'sse_connected' && _state == RoomSessionState.reconnecting) {
      _setState(RoomSessionState.joined, 'SSE reconnected');
      _reconnectBackoffMs = 100; // Reset backoff
    }
  }

  /// Network state change — disconnect/reconnect handling
  void onNetworkStateChanged(bool online) {
    if (!online && _state == RoomSessionState.joined) {
      _setState(RoomSessionState.reconnecting, 'Network offline');
      _cancelHeartbeat();
      _scheduleReconnect();
    } else if (online && _state == RoomSessionState.reconnecting) {
      _setState(RoomSessionState.joined, 'Network online');
      _startHeartbeat();
    }
  }

  void dispose() {
    _cancelHeartbeat();
    _cancelReconnect();
    _eventController.close();
  }

  // Private helpers

  void _setState(RoomSessionState next, String reason) {
    if (_state == next) return;
    final prev = _state;
    _state = next;
    _eventController.add(
      RoomSessionStateChanged(
        previous: prev,
        current: next,
        reason: reason,
      ),
    );
  }

  void _startHeartbeat() {
    _cancelHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) async {
        await heartbeat(
          onError: (reason) {
            debugPrint('Heartbeat error: $reason');
          },
        );
      },
    );
  }

  void _cancelHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    _cancelReconnect();
    final delay = Duration(milliseconds: _reconnectBackoffMs);
    _reconnectBackoffTimer = Timer(delay, () async {
      if (_state != RoomSessionState.reconnecting) return;

      // Backoff double, max 30s
      _reconnectBackoffMs = (_reconnectBackoffMs * 2).clamp(0, 30000);

      await join(
        onError: (reason) {
          debugPrint('Reconnect error: $reason');
          if (_state == RoomSessionState.reconnecting) {
            _scheduleReconnect(); // Retry
          }
        },
      );
    });
  }

  void _cancelReconnect() {
    _reconnectBackoffTimer?.cancel();
    _reconnectBackoffTimer = null;
  }

  void _syncPresenceIds() {
    _knownPresenceIds.clear();
    for (final p in _canonicalPresence) {
      if (p.id.trim().isNotEmpty) {
        _knownPresenceIds.add(p.id.trim());
      }
    }
  }

  void _clearCanonicalState() {
    _canonicalPresence = [];
    _canonicalSeats = [];
    _knownPresenceIds.clear();
  }
}
