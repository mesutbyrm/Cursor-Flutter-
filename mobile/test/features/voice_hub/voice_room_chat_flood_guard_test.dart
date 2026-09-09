import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_chat_flood_guard.dart';

void main() {
  test('tryAcquire blocks rapid sends', () {
    final guard = VoiceRoomChatFloodGuard(minIntervalMs: 1000);
    expect(guard.tryAcquire(), isNull);
    expect(guard.tryAcquire(), isNotNull);
  });

  test('tryAcquire blocks burst over window limit', () {
    final guard = VoiceRoomChatFloodGuard(
      minIntervalMs: 0,
      windowSeconds: 10,
      maxMessagesInWindow: 3,
    );
    expect(guard.tryAcquire(), isNull);
    expect(guard.tryAcquire(), isNull);
    expect(guard.tryAcquire(), isNull);
    expect(guard.tryAcquire(), isNotNull);
  });

  test('isDuplicateContent detects repeated text', () {
    final guard = VoiceRoomChatFloodGuard();
    final now = DateTime.now();
    final dup = guard.isDuplicateContent(
      content: 'Merhaba',
      userId: 'u1',
      recent: [
        (content: 'Merhaba', userId: 'u1', createdAt: now),
      ],
    );
    expect(dup, isTrue);
    final other = guard.isDuplicateContent(
      content: 'Merhaba',
      userId: 'u2',
      recent: [
        (content: 'Merhaba', userId: 'u1', createdAt: now),
      ],
    );
    expect(other, isFalse);
  });
}
