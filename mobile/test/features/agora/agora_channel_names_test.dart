import 'package:canlifal_social/features/agora/domain/agora_channel_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgoraChannelNames', () {
    test('prefixes bare room id', () {
      expect(AgoraChannelNames.forRoom('abc123'), 'room_abc123');
    });

    test('preserves existing room_ and live- prefixes', () {
      expect(AgoraChannelNames.forRoom('room_abc123'), 'room_abc123');
      expect(
        AgoraChannelNames.forRoom('live-123456'),
        'live-123456',
      );
    });

    test('forVoiceRoom uses voice_room_ prefix for bare id', () {
      expect(AgoraChannelNames.forVoiceRoom('abc123'), 'voice_room_abc123');
      expect(
        AgoraChannelNames.forVoiceRoom('voice_room_abc123'),
        'voice_room_abc123',
      );
    });

    test('empty input returns empty', () {
      expect(AgoraChannelNames.forRoom(''), '');
      expect(AgoraChannelNames.forRoom('  '), '');
    });
  });
}
