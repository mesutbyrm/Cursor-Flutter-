import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import '../../../../fortune/domain/entities/user_fortune_entity.dart';
import '../../../../fortune/presentation/providers/fortune_api_providers.dart';
import '../../../../shorts/domain/entities/short_video_entity.dart';
import '../../../../shorts/presentation/providers/shorts_providers.dart';
import '../../../../social/presentation/providers/user_social_posts_notifier.dart';
import '../../../domain/entities/profile_stats_entity.dart';
import '../../providers/broadcast_history_notifier.dart';
import '../../widgets/premium/profile_glass.dart';

/// İçeriklerim — 6 sekmeli grid görünümü.
class ProfileContentSection extends ConsumerStatefulWidget {
  const ProfileContentSection({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfileContentSection> createState() =>
      _ProfileContentSectionState();
}

class _ProfileContentSectionState extends ConsumerState<ProfileContentSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(title: 'İçeriklerim'),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            indicatorColor: AppThemeColors.accentPink,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Videolar'),
              Tab(text: 'Fallarım'),
              Tab(text: 'Canlı Yayınlarım'),
              Tab(text: 'İzlediklerim'),
              Tab(text: 'Favoriler'),
              Tab(text: 'Taslaklar'),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _tabs,
            builder: (context, _) {
              return switch (_tabs.index) {
                1 => _FortunesTab(),
                2 => _LiveStreamsTab(),
                3 => _WatchedTab(),
                4 => _FavoritesTab(),
                5 => _DraftsTab(),
                _ => _VideosTab(userId: widget.userId),
              };
            },
          ),
        ],
      ),
    );
  }
}

class _VideosTab extends ConsumerWidget {
  const _VideosTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userSocialPostsNotifierProvider(userId));

    return postsAsync.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Videolar yüklenemedi'),
      data: (posts) {
        if (posts.isEmpty) {
          return const _EmptyMessage('Henüz video yok');
        }
        return _VideoGrid(posts: posts);
      },
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.posts});

  final List<PostEntity> posts;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 14,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) => _VideoCard(post: posts[index]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final thumb = post.mediaUrl;
    final views = post.viewsCount > 0 ? post.viewsCount : post.viewCount;
    final date = post.createdAt != null
        ? DateFormat('d MMM yyyy', 'tr').format(post.createdAt!.toLocal())
        : '';

    return GestureDetector(
      onTap: () => context.push('/social'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF1A0F3D)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null && thumb.isNotEmpty)
                CanlifalNetworkImage(url: thumb, fit: BoxFit.cover)
              else
                Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 36,
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _MiniStat(Icons.visibility_rounded, views),
                          const SizedBox(width: 8),
                          _MiniStat(Icons.favorite_rounded, post.likesCount),
                          const SizedBox(width: 8),
                          _MiniStat(
                            Icons.chat_bubble_outline_rounded,
                            post.commentsCount,
                          ),
                        ],
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value);

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.white),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FortunesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(fortuneHistoryProvider);

    return history.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Fallar yüklenemedi'),
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyMessage('Henüz fal kaydı yok');
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _FortuneCard(fortune: items[index]),
        );
      },
    );
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({required this.fortune});

  final UserFortuneEntity fortune;

  @override
  Widget build(BuildContext context) {
    final title = fortune.summary?.trim().isNotEmpty == true
        ? fortune.summary!
        : fortune.type;
    final date = fortune.createdAt != null
        ? DateFormat('d MMM yyyy', 'tr').format(fortune.createdAt!.toLocal())
        : '';

    return GestureDetector(
      onTap: () => context.push('/fortune/detail/${fortune.id}'),
      child: ProfileGlass(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F)),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            if (date.isNotEmpty)
              Text(
                date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveStreamsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(broadcastHistoryNotifierProvider);

    return history.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Yayın geçmişi yüklenemedi'),
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyMessage('Henüz canlı yayın yok');
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _BroadcastCard(item: items[index]),
        );
      },
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.item});

  final BroadcastHistoryItemEntity item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/broadcast-history'),
      child: ProfileGlass(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.live_tv_rounded, color: AppThemeColors.liveRed),
            const Spacer(),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            Text(
              '${item.coinsEarned} J · ${item.giftCount} hediye',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(viewedShortsProvider);

    return watched.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('İzleme geçmişi yüklenemedi'),
      data: (videos) => _ShortsGrid(videos: videos),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(userFavoritesProvider);

    return favorites.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Favoriler yüklenemedi'),
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyMessage('Henüz favori yok');
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final fav = items[index];
            return GestureDetector(
              onTap: () => context.push('/favorites'),
              child: ProfileGlass(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fav.imageUrl != null && fav.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CanlifalNetworkImage(
                          url: fav.imageUrl!,
                          height: 48,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(Icons.bookmark_rounded, color: Colors.white54),
                    const Spacer(),
                    Text(
                      fav.title ?? fav.targetType,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DraftsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.drive_file_rename_outline_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Taslak videolarınız burada görünür',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/shorts/upload'),
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: const Text('Video Yükle'),
          ),
        ],
      ),
    );
  }
}

class _ShortsGrid extends StatelessWidget {
  const _ShortsGrid({required this.videos});

  final List<ShortVideoEntity> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const _EmptyMessage('Henüz izlenen video yok');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 14,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final thumb = video.thumbnailUrl;
        return GestureDetector(
          onTap: () => context.push('/shorts'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFF1A0F3D)),
              child: thumb != null && thumb.isNotEmpty
                  ? CanlifalNetworkImage(url: thumb, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.play_circle_outline_rounded),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ContentSkeleton extends StatelessWidget {
  const _ContentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 9 / 14,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const PremiumSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: context.colors.onSurfaceMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
