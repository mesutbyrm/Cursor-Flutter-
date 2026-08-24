import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/social_story_ring_entity.dart';
import 'story_viewer_args.dart';

/// Hikâye görüntüleyiciye git.
void openStoryViewer(
  BuildContext context,
  SocialStoryRingEntity ring, {
  int initialIndex = 0,
}) {
  context.push(
    '/social/stories/view',
    extra: StoryViewerArgs(ring: ring, initialIndex: initialIndex),
  );
}
