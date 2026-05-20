import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/trtc_remote_datasource.dart';
import '../../domain/entities/trtc_credentials.dart';

final trtcRemoteProvider = Provider<TrtcRemoteDataSource>((ref) {
  return TrtcRemoteDataSource(ref.watch(dioProvider));
});

final trtcUserSigProvider = FutureProvider.family<TrtcCredentials, TrtcRoomKey>(
  (ref, key) async {
    return ref.read(trtcRemoteProvider).fetchUserSig(
          userId: key.userId,
          roomId: key.roomId,
        );
  },
);

class TrtcRoomKey {
  const TrtcRoomKey({required this.userId, required this.roomId});

  final String userId;
  final String roomId;

  @override
  bool operator ==(Object other) =>
      other is TrtcRoomKey && other.userId == userId && other.roomId == roomId;

  @override
  int get hashCode => Object.hash(userId, roomId);
}
