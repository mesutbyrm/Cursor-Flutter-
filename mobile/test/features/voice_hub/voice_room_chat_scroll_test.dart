import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_chat_scroll.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('voiceRoomChatPendingOnNewMessages', () {
    test('increments only when not at latest', () {
      expect(
        voiceRoomChatPendingOnNewMessages(
          oldVisibleCount: 5,
          newVisibleCount: 7,
          wasAtLatest: false,
        ),
        2,
      );
      expect(
        voiceRoomChatPendingOnNewMessages(
          oldVisibleCount: 5,
          newVisibleCount: 7,
          wasAtLatest: true,
        ),
        0,
      );
    });
  });
}
