import '../../domain/entities/social_story_ring_entity.dart';

/// go_router `extra` — hikâye görüntüleyici argümanları.
class StoryViewerArgs {
  const StoryViewerArgs({
    required this.ring,
    this.initialIndex = 0,
    this.rings = const [],
  });

  final SocialStoryRingEntity ring;
  final int initialIndex;

  /// Şeritteki sıralı halkalar — biri bitince sonrakine geçilir. Boşsa yalnızca [ring].
  final List<SocialStoryRingEntity> rings;
}
