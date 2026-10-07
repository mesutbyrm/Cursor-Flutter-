import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_server_leave.dart';
import 'package:canlifal_social/features/trtc/data/datasources/live_room_remote_datasource.dart';

class _FakeChatRemote extends ChatRoomRemoteDataSource {
  _FakeChatRemote() : super(Dio());

  int clearSeatCalls = 0;
  int leavePresenceCalls = 0;
  String? lastLeaveKey;
  String? lastLeaveAlt;

  @override
  Future<void> clearSeat({
    required String roomKey,
    String? alternateKey,
    String? userId,
  }) async {
    clearSeatCalls++;
  }

  @override
  Future<bool> leavePresence(String roomKey, {String? alternateKey}) async {
    leavePresenceCalls++;
    lastLeaveKey = roomKey;
    lastLeaveAlt = alternateKey;
    return true;
  }
}

class _FakeLiveRemote extends LiveRoomRemoteDataSource {
  _FakeLiveRemote() : super(Dio());

  int leaveRoomCalls = 0;

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String roomType,
  }) async {
    leaveRoomCalls++;
  }
}

void main() {
  test('leaveVoiceRoomOnServer clears seat, live leave, then presence', () async {
    final chat = _FakeChatRemote();
    final live = _FakeLiveRemote();

    final ok = await leaveVoiceRoomOnServerWithClients(
      chatRemote: chat,
      liveRemote: live,
      roomKey: 'room-a',
      alternateKey: 'slug-a',
      userId: 'user-1',
    );

    expect(ok, isTrue);
    expect(chat.clearSeatCalls, 1);
    expect(live.leaveRoomCalls, 1);
    expect(chat.leavePresenceCalls, 1);
    expect(chat.lastLeaveKey, 'room-a');
    expect(chat.lastLeaveAlt, 'slug-a');
  });
}
