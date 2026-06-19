import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';

/// Oda listesi presence SSE — keşfet ekranında anlık çevrimiçi sayıları.
///
/// Üretim `presence` event'i: `{ "type":"presence", "roomId":"…", "onlineUsers":54 }`
class NotificationSseService extends BaseSseService {
  NotificationSseService()
      : _events = StreamController<RoomPresenceUpdate>.broadcast();

  final StreamController<RoomPresenceUpdate> _events;
  Stream<RoomPresenceUpdate> get events => _events.stream;

  String? _roomId;

  @override
  String streamPath() => ApiEndpoints.chatRoomStream(_roomId ?? '');

  @override
  bool get requiresAuth => false;

  Future<void> connectToRoom({
    required String roomId,
    required Future<String?> Function() accessToken,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    _roomId = id;
    await super.connect(accessToken: accessToken);
  }

  @override
  void onSseBlock(String block) {
    final map = BaseSseService.parseSseJsonBlock(block);
    if (map == null) return;
    final type = (map['type'] ?? '').toString().toLowerCase();
    if (type != 'presence' &&
        type != 'user_join' &&
        type != 'user_leave' &&
        type != 'room_update') {
      return;
    }

    final roomId = (map['roomId'] ?? _roomId ?? '').toString();
    if (roomId.isEmpty) return;

    final onlineUsers = _parseOnlineCount(map);
    if (onlineUsers == null) return;

    if (!_events.isClosed) {
      _events.add(RoomPresenceUpdate(roomId: roomId, onlineUsers: onlineUsers));
    }
  }

  int? _parseOnlineCount(Map<String, dynamic> map) {
    final direct = map['onlineUsers'] ?? map['onlineCount'] ?? map['count'];
    if (direct is num) return direct.toInt();
    final users = map['users'] ?? map['presence'] ?? map['members'];
    if (users is List) return users.length;
    return null;
  }

  @override
  Future<void> disconnect() async {
    _roomId = null;
    await super.disconnect();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    _events.close();
    super.dispose();
  }
}

class RoomPresenceUpdate {
  const RoomPresenceUpdate({
    required this.roomId,
    required this.onlineUsers,
  });

  final String roomId;
  final int onlineUsers;
}
