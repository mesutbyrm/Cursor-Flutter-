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
    this.fortuneType,
    this.viewCount = 0,
    this.isAutoShare = false,
    this.fortuneCount = 0,
    this.postType,
    this.likedByMe = false,
  });

  final String id;
  final UserEntity author;
  final String? caption;
  final String? mediaUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;
  /// Örn. `kahve-fali` — canlifal.com `/api/social/posts`.
  final String? fortuneType;
  final int viewCount;
  final bool isAutoShare;
  /// Aynı fal / paylaşımı gören kişi sayısı (canlifal `fortuneCount`).
  final int fortuneCount;
  /// Örn. `fortune`, `text` — canlifal `postType`.
  final String? postType;

  /// Oturumlu kullanıcı bu gönderiyi beğendi mi.
  final bool likedByMe;

  PostEntity copyWith({
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
  }) =>
      PostEntity(
        id: id,
        author: author,
        caption: caption,
        mediaUrl: mediaUrl,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        createdAt: createdAt,
        fortuneType: fortuneType,
        viewCount: viewCount,
        isAutoShare: isAutoShare,
        fortuneCount: fortuneCount,
        postType: postType,
        likedByMe: likedByMe ?? this.likedByMe,
      );

  @override
  List<Object?> get props => [
        id,
        author,
        caption,
        mediaUrl,
        likesCount,
        commentsCount,
        createdAt,
        fortuneType,
        viewCount,
        isAutoShare,
        fortuneCount,
        postType,
        likedByMe,
      ];
}
