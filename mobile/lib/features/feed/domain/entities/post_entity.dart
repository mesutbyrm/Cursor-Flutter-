import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';

class PostEntity extends Equatable {
  const PostEntity({
    required this.id,
    required this.author,
    this.caption,
    this.mediaUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.createdAt,
  });

  final String id;
  final UserEntity author;
  final String? caption;
  final String? mediaUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, author, caption, mediaUrl, likesCount, commentsCount, createdAt];
}
