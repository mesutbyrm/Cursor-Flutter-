import 'package:dio/dio.dart';

import '../../../../trtc/domain/entities/live_join_room_result.dart';
import 'live_field_gift_api.dart';
import 'live_field_message_api.dart';
import 'live_field_online_users_api.dart';
import 'live_field_pk_api.dart';
import 'live_field_room_discovery_api.dart';
import 'live_field_room_lifecycle_api.dart';
import 'live_field_seats_api.dart';

export 'live_field_gift_api.dart';
export 'live_field_message_api.dart';
export 'live_field_online_users_api.dart';
export 'live_field_pk_api.dart';
export 'live_field_room_discovery_api.dart';
export 'live_field_room_lifecycle_api.dart';
export 'live_field_seats_api.dart';

/// 7 saha `/api/live/*` API — birleşik erişim katmanı.
class LiveFieldApiRemoteDataSource {
  LiveFieldApiRemoteDataSource(Dio dio)
      : lifecycle = LiveFieldRoomLifecycleApi(dio),
        discovery = LiveFieldRoomDiscoveryApi(dio),
        seats = LiveFieldSeatsApi(dio),
        messages = LiveFieldMessageApi(dio),
        gifts = LiveFieldGiftApi(dio),
        pk = LiveFieldPkApi(dio),
        onlineUsers = LiveFieldOnlineUsersApi(dio);

  final LiveFieldRoomLifecycleApi lifecycle;
  final LiveFieldRoomDiscoveryApi discovery;
  final LiveFieldSeatsApi seats;
  final LiveFieldMessageApi messages;
  final LiveFieldGiftApi gifts;
  final LiveFieldPkApi pk;
  final LiveFieldOnlineUsersApi onlineUsers;

  // Kısayollar — lifecycle
  Future<Map<String, dynamic>> createRoom({
    String? title,
    String? description,
    String? category,
    String? thumbnailUrl,
    String? coverUrl,
  }) =>
      lifecycle.createRoom(
        title: title,
        description: description,
        category: category,
        thumbnailUrl: thumbnailUrl,
        coverUrl: coverUrl,
      );

  Future<LiveJoinRoomResult> joinRoom({
    required String roomId,
    required String roomType,
    String? nickname,
  }) =>
      lifecycle.joinRoom(
        roomId: roomId,
        roomType: roomType,
        nickname: nickname,
      );

  Future<void> leaveRoom({
    required String roomId,
    required String roomType,
  }) =>
      lifecycle.leaveRoom(roomId: roomId, roomType: roomType);

  Future<LiveHeartbeatResult> heartbeat({
    required String roomId,
    required String roomType,
  }) =>
      lifecycle.heartbeat(roomId: roomId, roomType: roomType);
}
