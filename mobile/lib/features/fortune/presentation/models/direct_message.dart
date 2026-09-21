class DirectMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool read;
  final DateTime createdAt;

  DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.read,
    required this.createdAt,
  });

  DirectMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    bool? read,
    DateTime? createdAt,
  }) {
    return DirectMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
