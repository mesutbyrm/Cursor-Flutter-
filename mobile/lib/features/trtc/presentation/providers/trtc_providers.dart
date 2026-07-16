import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/live_room_remote_datasource.dart';
import '../../data/datasources/trtc_remote_datasource.dart';
import '../../domain/entities/trtc_credentials.dart';
import '../trtc_live_room_coordinator.dart';
import '../trtc_room_manager.dart';

final trtcRemoteProvider = Provider<TrtcRemoteDataSource>((ref) {
  return TrtcRemoteDataSource(ref.watch(dioProvider));
});

final liveRoomRemoteProvider = Provider<LiveRoomRemoteDataSource>((ref) {
  return LiveRoomRemoteDataSource(ref.watch(dioProvider));
});

final trtcUserSigProvider = FutureProvider.family<TrtcCredentials, TrtcRoomKey>(
  (ref, key) async {
    final remote = ref.read(trtcRemoteProvider);
    try {
      return await remote.fetchToken(
        roomId: key.roomId,
        role: key.role ?? 'audience',
      );
    } catch (_) {
      return remote.fetchUserSig(
        userId: key.userId,
        roomId: key.roomId,
      );
    }
  },
);

final trtcRoomManagerProvider = Provider<TrtcRoomManager>((ref) {
  final manager = TrtcRoomManager();
  ref.onDispose(manager.dispose);
  return manager;
});

class TrtcRoomKey {
  const TrtcRoomKey({
    required this.userId,
    required this.roomId,
    this.role,
  });

  final String userId;
  final String roomId;
  final String? role;

  @override
  bool operator ==(Object other) =>
      other is TrtcRoomKey &&
      other.userId == userId &&
      other.roomId == roomId &&
      other.role == role;

  @override
  int get hashCode => Object.hash(userId, roomId, role);
}

TrtcLiveRoomCoordinator createTrtcLiveRoomCoordinator(Ref ref) {
  return TrtcLiveRoomCoordinator(
    liveRoom: ref.read(liveRoomRemoteProvider),
    trtcRemote: ref.read(trtcRemoteProvider),
    roomManager: ref.read(trtcRoomManagerProvider),
  );
}
