import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:canlifal_social/core/performance/list_perf.dart';
import 'package:canlifal_social/core/widgets/lazy_list_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

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
import '../../../../social/presentation/providers/social_providers.dart';
import '../../../../social/presentation/utils/story_navigation.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import '../../../domain/entities/profile_stats_entity.dart';
import '../../providers/broadcast_history_notifier.dart';
import '../../widgets/premium/profile_glass.dart';
import '../profile_theme.dart';

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

  /// Ana 5 sekme dışındaki içerikler (Kaydedilen, Canlı Yayınlarım…).
  /// -1 → ana sekme gösterilir.
  int _extra = -1;

  static const _extras = <String>[
    'Kaydedilen',
    'Canlı Yayınlarım',
    'İzlediklerim',
    'Favoriler',
    'Taslaklar',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabIndex = TabIndexListenable(_tabs);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging && _extra != -1) {
        setState(() => _extra = -1);
      }
    });
  }

  @override
  void dispose() {
    _tabIndex.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Widget _extraBody() => switch (_extra) {
        0 => _ShortsSavedTab(userId: widget.userId),
        1 => _LiveStreamsTab(),
        2 => _WatchedTab(),
        3 => _FavoritesTab(),
        _ => _DraftsTab(userId: widget.userId),
      };

  @override
  Widget build(BuildContext context) {
    final accent = ProfilePremiumTheme.accentOf(context);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(title: 'İçeriklerim'),
          // Kaymayan, ekrana yayılan 5 sekme (küçük ekranlarda taşmaz).
          TabBar(
            controller: _tabs,
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5),
            indicatorColor: _extra == -1 ? accent : Colors.transparent,
            labelColor: ProfilePremiumTheme.textOf(context),
            unselectedLabelColor: ProfilePremiumTheme.textMutedOf(context),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                height: 58,
                icon: Icon(Icons.grid_on_rounded, size: 20),
                child: _TabLabel('Gönderiler'),
              ),
              Tab(
                height: 58,
                icon: Icon(Icons.play_circle_outline_rounded, size: 21),
                child: _TabLabel('Videolar'),
              ),
              Tab(
                height: 58,
                icon: Icon(Icons.auto_stories_rounded, size: 20),
                child: _TabLabel('Hikâyeler'),
              ),
              Tab(
                height: 58,
                icon: Icon(Icons.favorite_border_rounded, size: 20),
                child: _TabLabel('Beğeniler'),
              ),
              Tab(
                height: 58,
                icon: Icon(Icons.auto_awesome_rounded, size: 20),
                child: _TabLabel('Fal Aktiviteleri'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _extras.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(_extras[i], style: const TextStyle(fontSize: 12)),
                selected: _extra == i,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => setState(() => _extra = v ? i : -1),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_extra != -1)
            _extraBody()
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: ListenableBuilder(
                key: ValueKey(_tabIndex.index),
                listenable: _tabIndex,
                builder: (context, _) {
                  return switch (_tabIndex.index) {
                    1 => _VideosTab(userId: widget.userId),
                    2 => _StoriesTab(userId: widget.userId),
                    3 => _ShortsLikedTab(userId: widget.userId),
                    4 => _FortunesTab(),
                    _ => _PostsTab(userId: widget.userId),
                  };
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1, softWrap: false),
        ),
      );
}

/// Gönderiler — kullanıcının sosyal paylaşımları (3 kolon ızgara).
class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userSocialPostsProvider(userId));
    return posts.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Gönderiler yüklenemedi'),
      data: (items) {
        if (items.isEmpty) return const _EmptyMessage('Henüz gönderi yok');
        return _MediaGrid(
          count: items.length,
          builder: (context, i) => _PostTile(post: items[i]),
        );
      },
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final url = post.mediaUrl;
    final hasImage = url != null && url.startsWith('http');
    return GestureDetector(
      onTap: () => context.push('/social/post/${post.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF1A0F3D)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                CanlifalNetworkImage(url: url, fit: BoxFit.cover)
              else
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      post.caption ?? '',
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ),
              Positioned(
                left: 6,
                bottom: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hikâyeler — oturum kullanıcısının aktif hikâyeleri (hikâye halkalarından).
class _StoriesTab extends ConsumerWidget {
  const _StoriesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rings = ref.watch(socialStoryRingsProvider);
    return rings.when(
      loading: () => const _ContentSkeleton(),
      error: (_, _) => const _EmptyMessage('Hikâyeler yüklenemedi'),
      data: (all) {
        final mine = all.where((r) => r.user.id == userId).toList();
        final ring = mine.isEmpty ? null : mine.first;
        if (ring == null || ring.stories.isEmpty) {
          return const _EmptyMessage('Aktif hikâyen yok');
        }
        return _MediaGrid(
          count: ring.stories.length,
          builder: (context, i) {
            final story = ring.stories[i];
            final isVideo = story.type.toLowerCase().contains('video');
            return GestureDetector(
              onTap: () => openStoryViewer(
                context,
                ring,
                initialIndex: i,
                rings: all,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0xFF1A0F3D)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!isVideo && story.mediaUrl.startsWith('http'))
                        CanlifalNetworkImage(url: story.mediaUrl, fit: BoxFit.cover)
                      else
                        const Center(
                          child: Icon(Icons.play_circle_outline_rounded, size: 30),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Üç kolonlu, kaydırılmayan (iç içe) medya ızgarası.
class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.count, required this.builder});

  final int count;
  final Widget Function(BuildContext, int) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 3;
        const spacing = 8.0;
        const aspect = 9 / 14;
        final h = ListPerf.nestedGridHeight(
          itemCount: count,
          crossAxisCount: cols,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          crossAxisExtent: c.maxWidth,
        );
        return SizedBox(
          height: h,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            addRepaintBoundaries: false,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspect,
            ),
            itemCount: count,
            itemBuilder: builder,
          ),
        );
      },
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
        return ShortsProfileGrid(videos: videos, nestedInProfileScroll: true);
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
        return ShortsProfileGrid(videos: videos, nestedInProfileScroll: true);
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
        return ShortsProfileGrid(videos: videos, nestedInProfileScroll: true);
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5B21B6), Color(0xFF190A36)],
                ),
              ),
            ),
            Positioned(
              right: -22,
              top: -18,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 86,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Text(
                  fortune.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.68),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF2D55), Color(0xFF210713)],
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -14,
              child: Icon(
                Icons.live_tv_rounded,
                size: 86,
                color: Colors.white.withValues(alpha: 0.11),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Text(
                  'CANLI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _miniMetric(Icons.monetization_on_rounded, '${item.coinsEarned} J'),
                      _miniMetric(Icons.card_giftcard_rounded, '${item.giftCount} hediye'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
                      Icon(
                        Icons.bookmark_rounded,
                        color: ProfilePremiumTheme.textMutedOf(context),
                      ),
                    const Spacer(),
                    Text(
                      fav.title ?? fav.targetType,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: ProfilePremiumTheme.textOf(context),
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
                  color: ProfilePremiumTheme.textMutedOf(context),
                ),
                const SizedBox(height: 12),
                Text(
                  'Taslak videolarınız burada görünür',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ProfilePremiumTheme.textSecondaryOf(context),
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
                    Icon(
                      Icons.movie_creation_outlined,
                      color: ProfilePremiumTheme.textMutedOf(context),
                    ),
                    const Spacer(),
                    Text(
                      draft.previewLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: ProfilePremiumTheme.textOf(context),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        const spacing = 8.0;
        const aspect = 9 / 14;
        final gridHeight = ListPerf.nestedGridHeight(
          itemCount: videos.length,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          crossAxisExtent: constraints.maxWidth,
        );
        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            addRepaintBoundaries: false,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspect,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 3;
          const spacing = 8.0;
          const aspect = 9 / 14;
          const itemCount = 6;
          final gridHeight = ListPerf.nestedGridHeight(
            itemCount: itemCount,
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspect,
            crossAxisExtent: constraints.maxWidth,
          );
          return SizedBox(
            height: gridHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              addRepaintBoundaries: false,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspect,
              ),
              itemCount: itemCount,
              itemBuilder: (_, _) => const PremiumSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          );
        },
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
