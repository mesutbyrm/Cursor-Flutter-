import 'package:equatable/equatable.dart';

import '../utils/dm_message_codec.dart';

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
    this.lastMessageAt,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastMessageAt;

  @override
  List<Object?> get props =>
      [id, title, subtitle, avatarUrl, unreadCount, isOnline, lastMessageAt];
}

/// Gelen mesaj isteği — `GET /api/messages` yanıtındaki `requests` dizisi.
///
/// Gizliliği "takipçiler" ya da "kimse" olan bir kullanıcıya ilk kez yazılırken
/// sunucu doğrudan mesajı reddedip önce istek bekliyor. İstekler gelen kutusunda
/// gösterilmediği için karşı taraf mesajı hiç görmüyordu.
class MessageRequestEntity extends Equatable {
  const MessageRequestEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderUsername,
    this.senderImage,
    this.message,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? senderUsername;
  final String? senderImage;
  final String? message;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, senderId, senderName, senderUsername, senderImage, message, createdAt];
}

class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.text,
    required this.isMine,
    this.createdAt,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.replyTo,
    this.forwardedFrom,
    this.rawText,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime? createdAt;
  final MessageDeliveryStatus deliveryStatus;
  final DmReplyMeta? replyTo;
  final String? forwardedFrom;
  final String? rawText;

  @override
  List<Object?> get props =>
      [id, text, isMine, createdAt, deliveryStatus, replyTo, forwardedFrom];
}
