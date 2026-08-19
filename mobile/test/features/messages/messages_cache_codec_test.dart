import 'package:canlifal_social/features/messages/data/messages_cache_codec.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/messages/domain/utils/dm_message_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation encode/decode roundtrip', () {
    const c = ConversationEntity(
      id: 'u1',
      title: 'Test',
      subtitle: 'Hi',
      unreadCount: 1,
      isOnline: false,
    );
    expect(decodeConversation(encodeConversation(c)), c);
  });

  test('message with reply metadata roundtrip', () {
    final m = MessageEntity(
      id: 'm2',
      text: 'Yanıt',
      isMine: false,
      createdAt: DateTime.utc(2026, 1, 1),
      deliveryStatus: MessageDeliveryStatus.sent,
      replyTo: DmReplyMeta(id: 'm1', text: 'Orijinal'),
    );
    final decoded = decodeMessage(encodeMessage(m));
    expect(decoded.replyTo?.id, 'm1');
    expect(decoded.text, 'Yanıt');
  });
}
