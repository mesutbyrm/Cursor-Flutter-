import 'package:canlifal_social/features/messages/data/messages_cache_codec.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:flutter_test/flutter_test.dart';

extension on ConversationEntity {
  ConversationEntity copyWithOnline(bool online) => ConversationEntity(
        id: id,
        title: title,
        subtitle: subtitle,
        avatarUrl: avatarUrl,
        unreadCount: unreadCount,
        isOnline: online,
        lastMessageAt: lastMessageAt,
        lastSeenAt: lastSeenAt,
      );
}

void main() {
  test('conversation encode/decode roundtrip', () {
    const c = ConversationEntity(
      id: 'u1',
      title: 'Ayşe',
      subtitle: 'Merhaba',
      avatarUrl: 'https://cdn.example/a.jpg',
      unreadCount: 2,
      isOnline: true,
      lastSeenAt: null,
    );
    final decoded = decodeConversation(encodeConversation(c));
    // Çevrimiçi durumu önbellekten geri gelmez (bayat yeşil nokta olmasın);
    // diğer tüm alanlar korunur.
    expect(decoded.isOnline, isFalse);
    expect(decoded, c.copyWithOnline(false));
  });

  test('conversation lastSeenAt roundtrip', () {
    final c = ConversationEntity(id: 'u2', title: 'Ali', lastSeenAt: DateTime.utc(2026, 10, 9, 21, 5));
    expect(decodeConversation(encodeConversation(c)), c);
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
