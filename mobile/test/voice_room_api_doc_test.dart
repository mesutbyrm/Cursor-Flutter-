import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_trtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRoomRemoteDataSource API doc', () {
    test('presence heartbeat interval is 25 seconds (PART4/PART10)', () {
      expect(
        ChatRoomRemoteDataSource.presenceHeartbeatInterval.inSeconds,
        25,
      );
    });

    test('presence and voice paths match production', () {
      expect(
        ChatRoomRemoteDataSource.presencePath('room123'),
        '/api/chat/rooms/room123/presence',
      );
      expect(
        ChatRoomRemoteDataSource.voicePath('room123'),
        '/api/chat/rooms/room123/voice',
      );
      expect(
        ChatRoomRemoteDataSource.messagesPath('room123'),
        '/api/chat/rooms/room123/messages',
      );
      expect(
        ChatRoomRemoteDataSource.backgroundsPath(),
        '/api/chat/rooms/backgrounds',
      );
      expect(
        ChatRoomRemoteDataSource.roomBackgroundPath('room123'),
        '/api/chat/rooms/room123/background',
      );
    });
  });

  group('VoiceTrtcEngine', () {
    test('exposes microphone permission helper', () {
      expect(VoiceTrtcEngine.requestMicrophonePermission, isNotNull);
    });

    test('trtcRoomIdFor matches entity trtcRoomId convention', () {
      expect(
        VoiceTrtcEngine.trtcRoomIdFor('room-abc'),
        'voice_room_room-abc',
      );
      expect(
        VoiceTrtcEngine.trtcRoomIdFor('voice_room_abc'),
        'voice_room_abc',
      );
    });
  });
}
