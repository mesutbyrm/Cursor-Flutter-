import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/social_story_ring_entity.dart';

/// Hikâye görüntüleyici — canlifal.com `storyGroups` içindeki tüm öğeleri gezer.
class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({super.key, required this.ring});

  final SocialStoryRingEntity ring;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  var _index = 0;

  List<SocialStoryItemEntity> get _stories {
    if (widget.ring.stories.isNotEmpty) return widget.ring.stories;
    final preview = widget.ring.previewUrl;
    if (preview == null || preview.isEmpty) return const [];
    return [SocialStoryItemEntity(id: 'preview', mediaUrl: preview)];
  }

  void _next() {
    final stories = _stories;
    if (stories.isEmpty) return;
    if (_index >= stories.length - 1) {
      context.pop();
      return;
    }
    setState(() => _index++);
  }

  void _previous() {
    if (_index <= 0) return;
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final stories = _stories;
    final story = stories.isNotEmpty ? stories[_index] : null;
    final url = story?.mediaUrl;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            )
          else
            Center(
              child: Text(
                '${widget.ring.user.display}\nHikâye önizlemesi yok',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _previous,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _next,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (stories.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        for (var i = 0; i < stories.length; i++)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: i <= _index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.ring.user.display,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (stories.length > 1)
                      Text(
                        '${_index + 1}/${stories.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    TextButton(
                      onPressed: () {
                        context.pop();
                        context.push('/user/${widget.ring.user.id}');
                      },
                      child: const Text('Profil'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (story?.caption != null && story!.caption!.trim().isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 64,
              child: Text(
                story.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Text(
                'canlifal.com hikâyeleri',
                style: TextStyle(
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
