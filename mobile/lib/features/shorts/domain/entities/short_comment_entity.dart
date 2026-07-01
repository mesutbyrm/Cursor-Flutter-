import 'package:equatable/equatable.dart';

import 'short_video_entity.dart';

class ShortCommentEntity extends Equatable {
  const ShortCommentEntity({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
    this.likesCount = 0,
    this.likedByMe = false,
    this.isPinned = false,
    this.parentId,
    this.repliesCount = 0,
    this.replies = const [],
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final ShortVideoAuthor author;
  final int likesCount;
  final bool likedByMe;
  final bool isPinned;
  final String? parentId;
  final int repliesCount;
  final List<ShortCommentEntity> replies;

  ShortCommentEntity copyWith({
    int? likesCount,
    bool? likedByMe,
    bool? isPinned,
    List<ShortCommentEntity>? replies,
  }) {
    return ShortCommentEntity(
      id: id,
      content: content,
      createdAt: createdAt,
      author: author,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      isPinned: isPinned ?? this.isPinned,
      parentId: parentId,
      repliesCount: repliesCount,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        createdAt,
        author,
        likesCount,
        likedByMe,
        isPinned,
        parentId,
        repliesCount,
        replies,
      ];
}
