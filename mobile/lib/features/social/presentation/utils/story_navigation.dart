import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/social_story_ring_entity.dart';
import 'story_viewer_args.dart';

/// Hikâye görüntüleyiciye git. [rings] verilirse kişiden kişiye geçilir.
void openStoryViewer(
  BuildContext context,
  SocialStoryRingEntity ring, {
  int initialIndex = 0,
  List<SocialStoryRingEntity> rings = const [],
}) {
  context.push(
    '/social/stories/view',
    extra: StoryViewerArgs(
      ring: ring,
      initialIndex: initialIndex,
      rings: rings,
    ),
  );
}
