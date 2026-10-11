import 'package:canlifal_social/features/voice_hub/girlive/girlive_bot_sse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('messageId uses eventId for dedupe', () {
    final id = GirLiveBotSse.messageIdFromPayload({
      'eventId': 42,
      'text': 'PK başladı!',
    });
    expect(id, 'girlive-bot-42');
  });

  test('unwrapPayload finds nested stream_signal bot message', () {
    final inner = GirLiveBotSse.unwrapPayload({
      'type': 'stream_signal',
      'signal': {
        'type': 'girlive_bot',
        'text': 'PK bitti!',
        'eventId': 99,
      },
    });
    expect(inner, isNotNull);
    expect(GirLiveBotSse.extractText(inner!), 'PK bitti!');
  });

  test('toVoiceMessage maps bot display name', () {
    final msg = GirLiveBotSse.toVoiceMessage({
      'eventId': 7,
      'text': '👋 Hoş geldin Ali!',
    });
    expect(msg.user?.name, GirLiveBotSse.botDisplayName);
    expect(msg.content, contains('Hoş geldin'));
  });
}
