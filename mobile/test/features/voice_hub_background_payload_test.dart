import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/voice_room_background_catalog.dart';

void main() {
  group('BG-002 VoiceRoomBackgroundCatalog.fromRoomPayload', () {
    test('backend column key backgroundImage is read', () {
      expect(
        VoiceRoomBackgroundCatalog.fromRoomPayload(
          {'backgroundImage': 'https://cdn.example.com/bg.jpg'},
        ),
        'https://cdn.example.com/bg.jpg',
      );
    });

    test('legacy keys still work', () {
      expect(
        VoiceRoomBackgroundCatalog.fromRoomPayload(
          {'backgroundImageUrl': 'https://a/b.jpg'},
        ),
        'https://a/b.jpg',
      );
      expect(
        VoiceRoomBackgroundCatalog.fromRoomPayload(
          {'backgroundUrl': 'https://a/c.jpg'},
        ),
        'https://a/c.jpg',
      );
    });

    test('empty value falls through to next key', () {
      expect(
        VoiceRoomBackgroundCatalog.fromRoomPayload(
          {'backgroundImage': '  ', 'backgroundUrl': 'https://a/d.jpg'},
        ),
        'https://a/d.jpg',
      );
    });

    test('nested room object and relative path', () {
      final url = VoiceRoomBackgroundCatalog.fromRoomPayload({
        'room': {'backgroundImage': '/images/voice-bg-3.jpg'},
      });
      expect(url, endsWith('/images/voice-bg-3.jpg'));
      expect(url, startsWith('http'));
    });

    test('no background → null', () {
      expect(
        VoiceRoomBackgroundCatalog.fromRoomPayload({'message': 'x'}),
        isNull,
      );
    });
  });

  test('backgroundImage: null varsayılana dönüş olarak tanınır', () {
    expect(
      VoiceRoomBackgroundCatalog.payloadClearsBackground(
        {'event': 'room_updated', 'backgroundImage': null},
      ),
      isTrue,
    );
    expect(
      VoiceRoomBackgroundCatalog.payloadClearsBackground(
        {'event': 'room_updated', 'backgroundImage': 'https://a/b.jpg'},
      ),
      isFalse,
    );
    expect(
      VoiceRoomBackgroundCatalog.payloadClearsBackground({'event': 'x'}),
      isFalse,
    );
  });
}
