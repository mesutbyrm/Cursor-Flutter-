import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';

/// Hikâye halkası — `/api/stories` → `storyGroups` (canlifal.com).
class SocialStoryRingEntity extends Equatable {
  const SocialStoryRingEntity({
    required this.user,
    this.previewUrl,
    this.isOwn = false,
  });

  final UserEntity user;
  final String? previewUrl;
  final bool isOwn;

  @override
  List<Object?> get props => [user, previewUrl, isOwn];
}
