import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/utils/live_chat_guard.dart';

void main() {
  setUp(LiveChatGuard.resetForTest);

  test('rejects empty messages', () {
    expect(LiveChatGuard.validate(''), isNotNull);
  });

  test('profanity is left to server moderation (GirLive Bot)', () {
    // İstemci engellerse mesaj sunucuya gitmez ve bot uyaramaz/atamaz.
    expect(LiveChatGuard.validate('bu bir test amk'), isNull);
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
