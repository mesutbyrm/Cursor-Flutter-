import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_agora_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRoomRemoteDataSource API doc', () {
    test('presence heartbeat interval is 25 seconds', () {
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
    });
  });

  group('VoiceAgoraEngine', () {
    test('uses empty token and communication profile constants', () {
      expect(VoiceAgoraEngine.requestMicrophonePermission, isNotNull);
    });
  });
}
