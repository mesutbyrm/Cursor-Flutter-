import 'package:equatable/equatable.dart';

class LiveStreamChatMessage extends Equatable {
  const LiveStreamChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    this.userId,
    this.userName,
    this.userImage,
    this.isSystem = false,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final String? userId;
  final String? userName;
  final String? userImage;
  final bool isSystem;

  factory LiveStreamChatMessage.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    Map<String, dynamic>? um;
    if (user is Map) um = Map<String, dynamic>.from(user);
    final created = json['createdAt']?.toString();
    return LiveStreamChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: created != null
          ? DateTime.tryParse(created) ?? DateTime.now()
          : DateTime.now(),
      userId: um?['id']?.toString(),
      userName: um?['name']?.toString() ??
          um?['displayName']?.toString() ??
          um?['nickname']?.toString(),
      userImage: um?['image']?.toString() ?? um?['avatarUrl']?.toString(),
      isSystem: json['kind']?.toString() == 'system',
    );
  }

  String get displayName => userName?.trim().isNotEmpty == true
      ? userName!.trim()
      : (isSystem ? 'Sistem' : 'Misafir');

  @override
  List<Object?> get props =>
      [id, content, createdAt, userId, userName, isSystem];
}
