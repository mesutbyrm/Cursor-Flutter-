import '../../domain/entities/social_story_ring_entity.dart';

/// go_router `extra` — hikâye görüntüleyici argümanları.
class StoryViewerArgs {
  const StoryViewerArgs({
    required this.ring,
    this.initialIndex = 0,
  });

  final SocialStoryRingEntity ring;
  final int initialIndex;
}
