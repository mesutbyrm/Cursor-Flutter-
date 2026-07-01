import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:canlifal_social/core/widgets/lazy_list_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../../fortune/domain/entities/user_fortune_entity.dart';
import '../../../../fortune/presentation/providers/fortune_api_providers.dart';
import '../../../../shorts/domain/entities/short_video_entity.dart';
import '../../../../shorts/domain/repositories/shorts_repository.dart';
import '../../../../shorts/presentation/providers/shorts_providers.dart';
import '../../../../shorts/presentation/studio/short_studio_providers.dart';
import '../../../../shorts/presentation/widgets/shorts_profile_content.dart';
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
  late final TabIndexListenable _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _tabIndex = TabIndexListenable(_tabs);
  }

  @override
  void dispose() {
    _tabIndex.dispose();
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
              Tab(text: 'Beğenilen'),
              Tab(text: 'Kaydedilen'),
              Tab(text: 'Fallarım'),
              Tab(text: 'Canlı Yayınlarım'),
              Tab(text: 'İzlediklerim'),
              Tab(text: 'Favoriler'),
              Tab(text: 'Taslaklar'),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _tabIndex,
            builder: (context, _) {
              return switch (_tabIndex.index) {
                1 => _ShortsLikedTab(userId: widget.userId),
                2 => _ShortsSavedTab(userId: widget.userId),
                3 => _FortunesTab(),
                4 => _LiveStreamsTab(),
                5 => _WatchedTab(),
                6 => _FavoritesTab(),
                7 => _DraftsTab(userId: widget.userId),
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
    final videosAsync = ref.watch(
      userShortVideosProvider((userId: userId, tab: ShortUserVideosTab.videos)),
    );

    return videosAsync.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Videolar yüklenemedi'),
      data: (videos) {
        if (videos.isEmpty) {
          return const _EmptyMessage('Henüz video yok');
        }
        return ShortsProfileGrid(videos: videos);
      },
    );
  }
}

class _ShortsLikedTab extends ConsumerWidget {
  const _ShortsLikedTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(
      userShortVideosProvider((userId: userId, tab: ShortUserVideosTab.liked)),
    );

    return videosAsync.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Beğenilen videolar yüklenemedi'),
      data: (videos) {
        if (videos.isEmpty) {
          return const _EmptyMessage('Henüz beğenilen video yok');
        }
        return ShortsProfileGrid(videos: videos);
      },
    );
  }
}

class _ShortsSavedTab extends ConsumerWidget {
  const _ShortsSavedTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(
      userShortVideosProvider((userId: userId, tab: ShortUserVideosTab.saved)),
    );

    return videosAsync.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Kaydedilen videolar yüklenemedi'),
      data: (videos) {
        if (videos.isEmpty) {
          return const _EmptyMessage('Henüz kaydedilen video yok');
        }
        return ShortsProfileGrid(videos: videos);
      },
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
        return LazyNestedGridView(
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
        return LazyNestedGridView(
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
        return LazyNestedGridView(
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

class _DraftsTab extends ConsumerWidget {
  const _DraftsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(shortSavedDraftsProvider(userId));

    return draftsAsync.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Taslaklar yüklenemedi'),
      data: (drafts) {
        if (drafts.isEmpty) {
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
        return LazyNestedGridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: drafts.length,
          itemBuilder: (context, index) {
            final draft = drafts[index];
            return GestureDetector(
              onTap: () => context.push('/shorts/upload'),
              child: ProfileGlass(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.movie_creation_outlined, color: Colors.white54),
                    const Spacer(),
                    Text(
                      draft.previewLabel,
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

class _ShortsGrid extends StatelessWidget {
  const _ShortsGrid({required this.videos});

  final List<ShortVideoEntity> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const _EmptyMessage('Henüz izlenen video yok');
    }
    return LazyNestedGridView(
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
          onTap: () => context.push('/shorts?videoId=${video.id}'),
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
      child: LazyNestedGridView(
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
