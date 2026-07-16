import '../../core/util/json_util.dart';

/// `POST /api/video-streams/{streamId}/comments` yorumu.
class StreamComment {
  const StreamComment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.userId,
    this.userName,
    this.userImage,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final String? userId;
  final String? userName;
  final String? userImage;

  factory StreamComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    Map<String, dynamic>? um;
    if (user is Map) um = Map<String, dynamic>.from(user);
    return StreamComment(
      id: pick(json, ['id', '_id'])?.toString() ??
          '${json['createdAt']}_${json['content']}'.hashCode.toString(),
      content: pick(json, ['content', 'text', 'body', 'message'])
              ?.toString() ??
          '',
      createdAt: DateTime.tryParse(
            pick(json, ['createdAt', 'sentAt', 'timestamp'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      userId: pick(json, ['userId'])?.toString() ??
          um?['id']?.toString() ??
          um?['userId']?.toString(),
      userName: pick(json, ['userName', 'nickname'])?.toString() ??
          um?['displayName']?.toString() ??
          um?['username']?.toString() ??
          um?['name']?.toString(),
      userImage: pick(json, ['userImage', 'avatar'])?.toString() ??
          um?['image']?.toString() ??
          um?['avatar']?.toString(),
    );
  }
}
