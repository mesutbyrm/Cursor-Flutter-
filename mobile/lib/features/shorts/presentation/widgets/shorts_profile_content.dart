import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../providers/shorts_providers.dart';
import '../utils/shorts_count_format.dart';

/// Doğrulanmış hesap rozeti — yalnızca `isVerified == true` iken gösterilir.
class ShortsVerifiedBadge extends StatelessWidget {
  const ShortsVerifiedBadge({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified_rounded,
      size: size,
      color: const Color(0xFF29B6F6),
    );
  }
}

/// TikTok/Instagram tarzı kısa video istatistik satırı.
class ShortsProfileStatsRow extends ConsumerWidget {
  const ShortsProfileStatsRow({
    super.key,
    required this.userId,
    this.fallbackFollowers = 0,
    this.fallbackFollowing = 0,
    this.fallbackLikes = 0,
    this.fallbackViews = 0,
    this.fallbackVideos = 0,
    this.tappable = true,
  });

  final String userId;
  final int fallbackFollowers;
  final int fallbackFollowing;
  final int fallbackLikes;
  final int fallbackViews;
  final int fallbackVideos;
  final bool tappable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(shortVideoProfileStatsProvider(userId));
    final hubStats = ref.watch(profileStatsProvider).valueOrNull;

    int pick(int primary, int secondary, int tertiary) {
      if (primary > 0) return primary;
      if (secondary > 0) return secondary;
      return tertiary;
    }

    Widget row({
      required int videos,
      required int followers,
      required int following,
      required int likes,
      required int views,
    }) {
      return ProfileGlass(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                label: 'Video',
                value: formatShortCount(videos),
              ),
            ),
            _divider(context),
            Expanded(
              child: _StatCell(
                label: 'Takipçi',
                value: formatShortCount(followers),
                onTap: tappable
                    ? () => context.push('/profile/followers?userId=$userId')
                    : null,
              ),
            ),
            _divider(context),
            Expanded(
              child: _StatCell(
                label: 'Takip',
                value: formatShortCount(following),
                onTap: tappable
                    ? () => context.push('/profile/following?userId=$userId')
                    : null,
              ),
            ),
            _divider(context),
            Expanded(
              child: _StatCell(
                label: 'Beğeni',
                value: formatShortCount(likes),
              ),
            ),
            _divider(context),
            Expanded(
              child: _StatCell(
                label: 'İzlenme',
                value: formatShortCount(views),
              ),
            ),
          ],
        ),
      );
    }

    final hubFollowers = hubStats?.followers ?? 0;
    final hubFollowing = hubStats?.following ?? 0;
    final hubLikes = hubStats?.likes ?? 0;
    final hubViews = hubStats?.profileViews ?? 0;

    if (statsAsync.isLoading && statsAsync.valueOrNull == null) {
      return row(
        videos: fallbackVideos,
        followers: pick(0, hubFollowers, fallbackFollowers),
        following: pick(0, hubFollowing, fallbackFollowing),
        likes: pick(0, hubLikes, fallbackLikes),
        views: pick(0, hubViews, fallbackViews),
      );
    }

    return statsAsync.when(
      loading: () => row(
        videos: fallbackVideos,
        followers: pick(0, hubFollowers, fallbackFollowers),
        following: pick(0, hubFollowing, fallbackFollowing),
        likes: pick(0, hubLikes, fallbackLikes),
        views: pick(0, hubViews, fallbackViews),
      ),
      error: (_, _) => row(
        videos: fallbackVideos,
        followers: pick(0, hubFollowers, fallbackFollowers),
        following: pick(0, hubFollowing, fallbackFollowing),
        likes: pick(0, hubLikes, fallbackLikes),
        views: pick(0, hubViews, fallbackViews),
      ),
      data: (stats) => row(
        videos: pick(stats.videosCount, 0, fallbackVideos),
        followers: pick(
          stats.followersCount,
          hubFollowers,
          fallbackFollowers,
        ),
        following: pick(
          stats.followingCount,
          hubFollowing,
          fallbackFollowing,
        ),
        likes: pick(stats.totalLikes, hubLikes, fallbackLikes),
        views: pick(stats.totalViews, 0, fallbackViews),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Videolar / Beğenilen / Kaydedilen sekmeli grid.
class ShortsProfileTabs extends ConsumerStatefulWidget {
  const ShortsProfileTabs({
    super.key,
    required this.userId,
    this.showLikedTab = false,
    this.showSavedTab = false,
    this.sectionTitle,
  });

  final String userId;
  final bool showLikedTab;
  final bool showSavedTab;
  final String? sectionTitle;

  @override
  ConsumerState<ShortsProfileTabs> createState() => _ShortsProfileTabsState();
}

class _ShortsProfileTabsState extends ConsumerState<ShortsProfileTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final count = 1 +
        (widget.showLikedTab ? 1 : 0) +
        (widget.showSavedTab ? 1 : 0);
    _tabs = TabController(length: count, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const Tab(icon: Icon(Icons.grid_on_rounded), text: 'Videolar'),
      if (widget.showLikedTab)
        const Tab(icon: Icon(Icons.favorite_border_rounded), text: 'Beğenilen'),
      if (widget.showSavedTab)
        const Tab(icon: Icon(Icons.bookmark_border_rounded), text: 'Kaydedilen'),
    ];

    final tabValues = <ShortUserVideosTab>[
      ShortUserVideosTab.videos,
      if (widget.showLikedTab) ShortUserVideosTab.liked,
      if (widget.showSavedTab) ShortUserVideosTab.saved,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sectionTitle != null) ...[
          Text(
            widget.sectionTitle!,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
        ],
        TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFF4081),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: tabs,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabs,
            children: [
              for (final tab in tabValues)
                ShortsProfileVideoGrid(userId: widget.userId, tab: tab),
            ],
          ),
        ),
      ],
    );
  }
}

class ShortsProfileVideoGrid extends ConsumerWidget {
  const ShortsProfileVideoGrid({
    super.key,
    required this.userId,
    required this.tab,
  });

  final String userId;
  final ShortUserVideosTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(
      userShortVideosProvider((userId: userId, tab: tab)),
    );

    return videos.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => Center(
        child: Text(
          'Videolar yüklenemedi',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              _emptyLabel(tab),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
          );
        }
        return ShortsProfileGrid(videos: list);
      },
    );
  }

  String _emptyLabel(ShortUserVideosTab tab) => switch (tab) {
        ShortUserVideosTab.liked => 'Henüz beğenilen video yok',
        ShortUserVideosTab.saved => 'Henüz kaydedilen video yok',
        _ => 'Henüz video yok',
      };
}

class ShortsProfileGrid extends StatelessWidget {
  const ShortsProfileGrid({
    super.key,
    required this.videos,
    this.nestedInProfileScroll = false,
  });

  final List<ShortVideoEntity> videos;
  /// Profil CustomScrollView içindeyse shrinkWrap zorunlu.
  final bool nestedInProfileScroll;

  @override
  Widget build(BuildContext context) {
    if (nestedInProfileScroll) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 9 / 14,
        ),
        itemCount: videos.length,
        addRepaintBoundaries: false,
        itemBuilder: (context, i) => _VideoTile(video: videos[i]),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 9 / 14,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) => _VideoTile(video: videos[i]),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final ShortVideoEntity video;

  @override
  Widget build(BuildContext context) {
    final v = video;
    return GestureDetector(
      onTap: () => context.push('/shorts?videoId=${v.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty
            ? CanlifalNetworkImage(url: v.thumbnailUrl!, fit: BoxFit.cover)
            : const ColoredBox(
                color: Color(0xFF1A0F3D),
                child: Center(
                  child: Icon(Icons.play_circle_outline, color: Colors.white54),
                ),
              ),
      ),
    );
  }
}
