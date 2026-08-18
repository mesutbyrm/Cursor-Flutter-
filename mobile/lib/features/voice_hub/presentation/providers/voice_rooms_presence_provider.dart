import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sse/sse_hub_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_sse_event.dart';

/// Keşfet listesinde anlık çevrimiçi sayıları — merkezi SSE hub (oda başına tek bağlantı).
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
  /// Discover ekranında aynı anda görünür/öncelikli odalar izlenir.
  static const maxTrackedRooms = 12;

  /// Ana sayfa şeridi — daha az eşzamanlı SSE (ANR önleme).
  static const homeTrackedRooms = 6;

  static const _connectStagger = Duration(milliseconds: 180);

  final Map<String, StreamSubscription<ChatRoomSseEvent>> _subs = {};
  var _syncGeneration = 0;

  @override
  VoiceRoomsPresenceState build() {
    ref.onDispose(_disposeAll);
    return const VoiceRoomsPresenceState();
  }

  /// Yalnızca çağıran ekran istediğinde SSE izleme başlar (kabuk açılışında değil).
  void mergeTrackRooms(List<VoiceRoomEntity> extra) {
    if (extra.isEmpty) return;
    final merged = <String, VoiceRoomEntity>{};
    for (final r in extra) {
      final key = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
      if (key.isEmpty) continue;
      merged[key] = r;
    }
    if (merged.isEmpty) return;
    _syncRooms(merged.values.toList());
  }

  void _syncRooms(List<VoiceRoomEntity> rooms) {
    final top = rooms.take(maxTrackedRooms).toList();
    final keys = <String>{};
    for (final room in top) {
      final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
      if (key.isEmpty) continue;
      keys.add(key);
    }
    final generation = ++_syncGeneration;
    unawaited(_staggerConnectRooms(keys.toList(growable: false), generation));
    for (final key in _subs.keys.toList()) {
      if (!keys.contains(key)) _disconnectRoom(key);
    }
    state = state.copyWith(connectedRooms: keys);
  }

  Future<void> _staggerConnectRooms(List<String> keys, int generation) async {
    for (var i = 0; i < keys.length; i++) {
      if (generation != _syncGeneration) return;
      final key = keys[i];
      final hub = ref.read(sseConnectionHubProvider);
      final service = hub.voiceRoom(key);
      final live = service.isLiveForRoom(key);
      if (_subs.containsKey(key) && live) {
        if (i < keys.length - 1) {
          await Future<void>.delayed(_connectStagger);
        }
        continue;
      }
      if (_subs.containsKey(key) && !live) {
        _disconnectRoom(key, releaseHub: false);
      }
      await _connectRoom(key);
      if (i < keys.length - 1) {
        await Future<void>.delayed(_connectStagger);
      }
    }
  }

  Future<void> _connectRoom(String roomId) async {
    final hub = ref.read(sseConnectionHubProvider);
    hub.attachVoiceRoom(roomId);
    final service = hub.voiceRoom(roomId);
    final tokens = ref.read(tokenStorageProvider);
    if (!service.isLiveForRoom(roomId)) {
      await service.connect(
        roomId: roomId,
        accessToken: tokens.readAccess,
      );
    }
    _subs[roomId]?.cancel();
    _subs[roomId] = service.events.listen((event) {
      final update = _presenceFromEvent(event, fallbackRoomId: roomId);
      if (update == null) return;
      final counts = Map<String, int>.from(state.counts);
      counts[update.roomId] = update.onlineUsers;
      state = state.copyWith(counts: counts);
    });
  }

  ({String roomId, int onlineUsers})? _presenceFromEvent(
    ChatRoomSseEvent event, {
    required String fallbackRoomId,
  }) {
    final map = event.data;
    switch (event.type) {
      case ChatRoomSseEventType.presence:
      case ChatRoomSseEventType.userJoin:
      case ChatRoomSseEventType.userLeave:
      case ChatRoomSseEventType.roomUpdate:
        break;
      default:
        return null;
    }
    final roomId =
        (map['roomId'] ?? map['roomKey'] ?? fallbackRoomId).toString().trim();
    if (roomId.isEmpty) return null;
    final online = _parseOnlineCount(map);
    if (online == null) return null;
    return (roomId: roomId, onlineUsers: online);
  }

  int? _parseOnlineCount(Map<String, dynamic> map) {
    final direct = map['onlineUsers'] ?? map['onlineCount'] ?? map['count'];
    if (direct is num) return direct.toInt();
    final users = map['users'] ?? map['presence'] ?? map['members'];
    if (users is List) return users.length;
    return null;
  }

  void patchRoomCount(String roomId, int count) {
    if (roomId.isEmpty || count < 0) return;
    final counts = Map<String, int>.from(state.counts);
    counts[roomId] = count;
    state = state.copyWith(counts: counts);
  }

  void _disconnectRoom(String roomId, {bool releaseHub = true}) {
    _subs.remove(roomId)?.cancel();
    if (releaseHub) {
      ref.read(sseConnectionHubProvider).releaseVoiceRoom(roomId);
    }
  }

  void _disposeAll() {
    _syncGeneration++;
    final keys = _subs.keys.toList();
    for (final sub in List.from(_subs.values)) {
      sub.cancel();
    }
    _subs.clear();
    try {
      final hub = ref.read(sseConnectionHubProvider);
      for (final key in keys) {
        hub.releaseVoiceRoom(key);
      }
    } catch (_) {
      // ProviderContainer dispose sırasında hub okunamayabilir.
    }
  }
}

final voiceRoomsPresenceProvider =
    NotifierProvider<VoiceRoomsPresenceNotifier, VoiceRoomsPresenceState>(
  VoiceRoomsPresenceNotifier.new,
);
