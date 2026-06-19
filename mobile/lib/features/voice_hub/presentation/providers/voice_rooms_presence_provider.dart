import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/token_storage.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import '../data/services/notification_sse_service.dart';

/// Keşfet listesinde anlık çevrimiçi sayıları — SSE presence (25 sn poll yerine).
class VoiceRoomsPresenceState {
  const VoiceRoomsPresenceState({
    this.counts = const {},
    this.connectedRooms = const {},
  });

  final Map<String, int> counts;
  final Set<String> connectedRooms;

  int countFor(VoiceRoomEntity room) {
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    return counts[key] ??
        counts[room.id] ??
        (room.displayOnline > 0 ? room.displayOnline : 0);
  }

  VoiceRoomsPresenceState copyWith({
    Map<String, int>? counts,
    Set<String>? connectedRooms,
  }) {
    return VoiceRoomsPresenceState(
      counts: counts ?? this.counts,
      connectedRooms: connectedRooms ?? this.connectedRooms,
    );
  }
}

class VoiceRoomsPresenceNotifier extends Notifier<VoiceRoomsPresenceState> {
  static const maxTrackedRooms = 12;

  final Map<String, NotificationSseService> _services = {};
  final Map<String, StreamSubscription<RoomPresenceUpdate>> _subs = {};

  @override
  VoiceRoomsPresenceState build() {
    ref.onDispose(_disposeAll);
    ref.listen(voiceRoomsProvider, (prev, next) {
      final rooms = next.valueOrNull;
      if (rooms != null) _syncRooms(rooms);
    });
    final rooms = ref.read(voiceRoomsProvider).valueOrNull;
    if (rooms != null) {
      Future.microtask(() => _syncRooms(rooms));
    }
    return const VoiceRoomsPresenceState();
  }

  void _syncRooms(List<VoiceRoomEntity> rooms) {
    final top = rooms.take(maxTrackedRooms).toList();
    final keys = <String>{};
    for (final room in top) {
      final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
      if (key.isEmpty) continue;
      keys.add(key);
      if (_services.containsKey(key)) continue;
      _connectRoom(key);
    }
    for (final key in _services.keys.toList()) {
      if (!keys.contains(key)) _disconnectRoom(key);
    }
    state = state.copyWith(connectedRooms: keys);
  }

  Future<void> _connectRoom(String roomId) async {
    final service = NotificationSseService();
    _services[roomId] = service;
    final tokens = ref.read(tokenStorageProvider);
    await service.connectToRoom(
      roomId: roomId,
      accessToken: tokens.readAccess,
    );
    _subs[roomId] = service.events.listen((update) {
      final counts = Map<String, int>.from(state.counts);
      counts[update.roomId] = update.onlineUsers;
      state = state.copyWith(counts: counts);
    });
  }

  void _disconnectRoom(String roomId) {
    _subs.remove(roomId)?.cancel();
    _services.remove(roomId)?.dispose();
  }

  void _disposeAll() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    for (final s in _services.values) {
      s.dispose();
    }
    _services.clear();
  }
}

final voiceRoomsPresenceProvider =
    NotifierProvider<VoiceRoomsPresenceNotifier, VoiceRoomsPresenceState>(
  VoiceRoomsPresenceNotifier.new,
);
