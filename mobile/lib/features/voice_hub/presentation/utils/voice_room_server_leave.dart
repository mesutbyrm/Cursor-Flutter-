import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trtc/data/datasources/live_room_remote_datasource.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../providers/chat_room_providers.dart';

/// Sunucuda tek bir sesli oda için tam çıkış: koltuk, live üyelik, presence (`leave=1`).
///
/// Oda değiştirirken veya açılış temizliğinde kullanılır; yalnızca `leavePresence`
/// çağırmak koltuk ve live kaydını bırakıp hayalet katılımcı bırakıyordu.
Future<bool> leaveVoiceRoomOnServer(
  Ref ref, {
  required String roomKey,
  String? alternateKey,
  String? userId,
}) =>
    leaveVoiceRoomOnServerWithClients(
      chatRemote: ref.read(chatRoomRemoteProvider),
      liveRemote: ref.read(liveRoomRemoteProvider),
      roomKey: roomKey,
      alternateKey: alternateKey,
      userId: userId,
    );

Future<bool> leaveVoiceRoomOnServerWithClients({
  required ChatRoomRemoteDataSource chatRemote,
  required LiveRoomRemoteDataSource liveRemote,
  required String roomKey,
  String? alternateKey,
  String? userId,
}) async {
  final key = roomKey.trim();
  if (key.isEmpty) return false;
  final uid = userId?.trim();
  if (uid != null && uid.isNotEmpty) {
    try {
      await chatRemote.clearSeat(
        roomKey: key,
        alternateKey: alternateKey,
        userId: uid,
      );
    } catch (_) {}
  }
  try {
    await liveRemote
        .leaveRoom(roomId: key, roomType: 'voice')
        .timeout(const Duration(seconds: 3));
  } catch (_) {}
  try {
    return await chatRemote.leavePresence(key, alternateKey: alternateKey);
  } catch (_) {
    return false;
  }
}
