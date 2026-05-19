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
    this.durationSeconds,
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
  /// Video süresi (saniye); API vermezse null.
  final int? durationSeconds;

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
        durationSeconds,
      ];
}
