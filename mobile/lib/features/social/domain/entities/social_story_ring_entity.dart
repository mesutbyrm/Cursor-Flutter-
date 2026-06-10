import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';

/// Hikâye halkası — `/api/stories` → `storyGroups` (canlifal.com).
class SocialStoryRingEntity extends Equatable {
  const SocialStoryRingEntity({
    required this.user,
    this.previewUrl,
    this.stories = const [],
    this.isOwn = false,
  });

  final UserEntity user;
  final String? previewUrl;
  final List<SocialStoryItemEntity> stories;
  final bool isOwn;

  @override
  List<Object?> get props => [user, previewUrl, stories, isOwn];
}

class SocialStoryItemEntity extends Equatable {
  const SocialStoryItemEntity({
    required this.id,
    required this.mediaUrl,
    this.type = 'image',
    this.caption,
    this.createdAt,
  });

  final String id;
  final String mediaUrl;
  final String type;
  final String? caption;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, mediaUrl, type, caption, createdAt];
}
