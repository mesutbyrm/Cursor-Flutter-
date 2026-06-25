import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/utils/live_chat_guard.dart';

void main() {
  setUp(LiveChatGuard.resetForTest);

  test('rejects empty messages', () {
    expect(LiveChatGuard.validate(''), isNotNull);
  });

  test('rejects profanity', () {
    expect(LiveChatGuard.validate('bu bir test amk'), isNotNull);
  });

  test('allows clean message', () {
    expect(LiveChatGuard.validate('Merhaba canlifal'), isNull);
  });

  test('sanitize masks profanity', () {
    expect(
      LiveChatGuard.sanitizeForDisplay('amk test'),
      contains('***'),
    );
  });
}
