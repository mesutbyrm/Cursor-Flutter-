import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../domain/repositories/shorts_repository.dart';
import '../providers/shorts_providers.dart';

/// Başka kullanıcı profilinde kısa video grid'i.
class UserShortsVideosSection extends ConsumerWidget {
  const UserShortsVideosSection({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(shortVideoProfileStatsProvider(userId));
    final videos = ref.watch(
      userShortVideosProvider((userId: userId, tab: ShortUserVideosTab.videos)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stats.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${s.videosCount} video · ${s.totalLikes} beğeni',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ),
        videos.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kısa Videolar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 9 / 14,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final v = list[i];
                    return GestureDetector(
                      onTap: () => context.push('/shorts?videoId=${v.id}'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: v.thumbnailUrl != null
                            ? CanlifalNetworkImage(
                                url: v.thumbnailUrl!,
                                fit: BoxFit.cover,
                              )
                            : const ColoredBox(
                                color: Color(0xFF1A0F3D),
                                child: Icon(Icons.play_circle_outline),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
    );
  }
}
