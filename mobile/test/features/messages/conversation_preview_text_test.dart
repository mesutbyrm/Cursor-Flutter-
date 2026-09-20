import 'package:canlifal_social/features/messages/domain/utils/conversation_preview_text.dart';
import 'package:canlifal_social/features/messages/domain/utils/dm_message_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes reply-wrapped preview like chat bubble', () {
    final raw = DmMessageCodec.wrapReply(
      replyId: '1',
      replyText: 'Merhaba',
      body: 'Cevap metni',
    );
    expect(conversationPreviewText(raw), 'Cevap metni');
  });

  test('call signal shows friendly label', () {
    expect(
      conversationPreviewText(DmMessageCodec.callInvite(callId: 'a', channelId: 'b')),
      'Sesli arama',
    );
  });
}
