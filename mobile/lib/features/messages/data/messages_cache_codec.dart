import '../domain/entities/message_entities.dart';

Map<String, dynamic> encodeConversation(ConversationEntity c) => {
      'id': c.id,
      'title': c.title,
      'subtitle': c.subtitle,
      'avatarUrl': c.avatarUrl,
      'unreadCount': c.unreadCount,
      'isOnline': c.isOnline,
      'lastMessageAt': c.lastMessageAt?.toIso8601String(),
    };

ConversationEntity decodeConversation(Map<String, dynamic> json) {
  return ConversationEntity(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString(),
    avatarUrl: json['avatarUrl']?.toString(),
    unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    isOnline: json['isOnline'] == true,
    lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
  );
}

Map<String, dynamic> encodeMessage(MessageEntity m) => {
      'id': m.id,
      'text': m.text,
      'isMine': m.isMine,
      'createdAt': m.createdAt?.toIso8601String(),
      'deliveryStatus': m.deliveryStatus.name,
    };

MessageEntity decodeMessage(Map<String, dynamic> json) {
  final statusRaw = json['deliveryStatus']?.toString() ?? 'sent';
  final status = MessageDeliveryStatus.values.firstWhere(
    (s) => s.name == statusRaw,
    orElse: () => MessageDeliveryStatus.sent,
  );
  return MessageEntity(
    id: json['id']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    isMine: json['isMine'] == true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    deliveryStatus: status,
  );
}
