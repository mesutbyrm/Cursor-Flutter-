import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/voice_room_background_catalog.dart';

void main() {
  group('VoiceRoomBackgroundCatalog', () {
    test('parses production room background objects', () {
      final urls = VoiceRoomBackgroundCatalog.parseApiList([
        {
          'roomId': 'cmokyb9o9007iod09gi6pb1tb',
          'backgroundImage': 'https://cdn.example.com/voice.jpeg',
        },
        {
          'imageUrl': '/uploads/voice-bg.jpg',
        },
      ]);

      expect(urls.first, 'https://cdn.example.com/voice.jpeg');
      expect(urls.last, endsWith('/uploads/voice-bg.jpg'));
    });
  });
}
