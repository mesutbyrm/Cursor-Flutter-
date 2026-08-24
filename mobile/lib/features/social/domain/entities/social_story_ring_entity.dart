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

  SocialStoryRingEntity copyWith({
    UserEntity? user,
    String? previewUrl,
    List<SocialStoryItemEntity>? stories,
    bool? isOwn,
  }) =>
      SocialStoryRingEntity(
        user: user ?? this.user,
        previewUrl: previewUrl ?? this.previewUrl,
        stories: stories ?? this.stories,
        isOwn: isOwn ?? this.isOwn,
      );

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
    this.durationMs,
  });

  final String id;
  final String mediaUrl;
  final String type;
  final String? caption;
  final DateTime? createdAt;
  /// Backend/medya süresi (ms) — yoksa görsel için varsayılan kullanılır.
  final int? durationMs;

  @override
  List<Object?> get props => [id, mediaUrl, type, caption, createdAt, durationMs];
}
