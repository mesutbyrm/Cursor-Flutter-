import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/social_story_ring_entity.dart';

/// Basit hikâye görüntüleyici — halkaya tıklanınca.
class StoryViewerPage extends StatelessWidget {
  const StoryViewerPage({super.key, required this.ring});

  final SocialStoryRingEntity ring;

  @override
  Widget build(BuildContext context) {
    final url = ring.previewUrl;
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
                child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
              ),
            )
          else
            Center(
              child: Text(
                '${ring.user.display}\nHikâye önizlemesi yok',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    ring.user.display,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.pop();
                    context.push('/user/${ring.user.id}');
                  },
                  child: const Text('Profil'),
                ),
              ],
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
