import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coordinators/room_session_manager.dart';

/// Room session manager — per-room instance
/// Use: ref.read(roomSessionManagerProvider(roomId))
final roomSessionManagerProvider = Provider.family<RoomSessionManager, String>(
  (ref, roomId) {
    final manager = RoomSessionManager(
      roomId: roomId,
      userId: '',
    );
    ref.onDispose(manager.dispose);
    return manager;
  },
);
