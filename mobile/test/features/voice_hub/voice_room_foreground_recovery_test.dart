import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_foreground_recovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('voiceRoomRouteIdFromLocations', () {
    test('extracts id from voice room path', () {
      expect(
        voiceRoomRouteIdFromLocations(['/voice-room/my-slug']),
        'my-slug',
      );
    });

    test('extracts id when nested pk route', () {
      expect(
        voiceRoomRouteIdFromLocations([
          '/voice-room/abc123/pk',
          '/voice-room/abc123',
        ]),
        'abc123',
      );
    });

    test('ignores list route', () {
      expect(
        voiceRoomRouteIdFromLocations(['/voice-rooms']),
        isNull,
      );
    });
  });
}
