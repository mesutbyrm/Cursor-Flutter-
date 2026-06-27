import 'package:canlifal_social/features/messages/data/messages_cache_codec.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation encode/decode roundtrip', () {
    const c = ConversationEntity(
      id: 'u1',
      title: 'Ayşe',
      subtitle: 'Merhaba',
      avatarUrl: 'https://cdn.example/a.jpg',
      unreadCount: 2,
      isOnline: true,
    );
    final decoded = decodeConversation(encodeConversation(c));
    expect(decoded, c);
  });

  test('message encode/decode roundtrip', () {
    const m = MessageEntity(
      id: 'm1',
      text: 'Selam',
      isMine: true,
      createdAt: null,
      deliveryStatus: MessageDeliveryStatus.delivered,
    );
    final decoded = decodeMessage(encodeMessage(m));
    expect(decoded.id, m.id);
    expect(decoded.text, m.text);
    expect(decoded.isMine, m.isMine);
    expect(decoded.deliveryStatus, m.deliveryStatus);
  });
}
