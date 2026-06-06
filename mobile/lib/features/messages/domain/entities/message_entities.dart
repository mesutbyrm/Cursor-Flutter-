import 'package:equatable/equatable.dart';

/// Mesaj iletim durumu (WhatsApp / Instagram DM tarzı).
enum MessageDeliveryStatus { sending, sent, delivered, read }

class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final int unreadCount;
  final bool isOnline;

  @override
  List<Object?> get props =>
      [id, title, subtitle, avatarUrl, unreadCount, isOnline];
}

class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.text,
    required this.isMine,
    this.createdAt,
    this.deliveryStatus = MessageDeliveryStatus.sent,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime? createdAt;
  final MessageDeliveryStatus deliveryStatus;

  @override
  List<Object?> get props => [id, text, isMine, createdAt, deliveryStatus];
}
