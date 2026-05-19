import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.unreadCount = 0,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final int unreadCount;

  @override
  List<Object?> get props => [id, title, subtitle, avatarUrl, unreadCount];
}

class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.text,
    required this.isMine,
    this.createdAt,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, text, isMine, createdAt];
}
