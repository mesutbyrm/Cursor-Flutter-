import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_section_header.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';

/// Web ana sayfadaki üst şerit: Profil, Mesajlar, Bildirim, Admin paneli.
class FeedTopShortcuts extends ConsumerWidget {
  const FeedTopShortcuts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppTheme.surface.withValues(alpha: 0.55),
          border: Border.all(
            color: AppTheme.cosmicPurple.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TopShort(
              label: 'Profil',
              child: UserAvatar(url: me?.avatarUrl, radius: 18),
              onTap: () => context.go('/profile'),
            ),
            _TopShort(
              label: 'Mesajlar',
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 24),
              onTap: () => context.go('/messages'),
            ),
            _TopShort(
              label: 'Bildirim',
              child: const Icon(Icons.notifications_none_rounded, size: 24),
              onTap: () => context.push('/notifications'),
            ),
            if (Env.useNextAuth)
              _TopShort(
                label: 'Admin',
                child: const Icon(Icons.auto_awesome_rounded, size: 24),
                onTap: () => context.push(
                  CanlifalWebRoute.location(
                    relativePath: '/admin',
                    title: 'Admin paneli',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopShort extends StatelessWidget {
  const _TopShort({
    required this.label,
    required this.child,
    required this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 36, child: Center(child: child)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `/api/stories` akışından gelen içerikle hikâye halkası (yazar bazlı tekilleştirilmiş).
class FeedStoriesStrip extends ConsumerWidget {
  const FeedStoriesStrip({super.key});

  static List<PostEntity> _uniqueAuthors(List<PostEntity> posts, int max) {
    final seen = <String>{};
    final out = <PostEntity>[];
    for (final p in posts) {
      if (seen.add(p.author.id)) out.add(p);
      if (out.length >= max) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedNotifierProvider);
    return feed.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          height: 96,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (posts) {
        final authors = _uniqueAuthors(posts, 14);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlowPanel(
            borderRadius: 18,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CosmicSectionHeader(
                  title: 'Hikâyeler',
                  showBar: false,
                  trailing: TextButton(
                    onPressed: () => context.push(
                      CanlifalWebRoute.location(
                        relativePath: '/',
                        title: 'Canlifal',
                      ),
                    ),
                    child: const Text('Tümü'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: 1 + authors.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return _StoryAddBubble(
                          onTap: () => context.push(
                            CanlifalWebRoute.location(
                              relativePath: '/',
                              title: 'Hikâye',
                            ),
                          ),
                        );
                      }
                      final p = authors[i - 1];
                      return _StoryAuthorBubble(
                        post: p,
                        onTap: () => context.push(
                          CanlifalWebRoute.location(
                            relativePath: '/',
                            title: p.author.display,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StoryAddBubble extends StatelessWidget {
  const _StoryAddBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.cosmicPurple.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  color: AppTheme.surfaceElevated,
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppTheme.accentSecondary, size: 30),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Hikâye ekle',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StoryAuthorBubble extends StatelessWidget {
  const _StoryAuthorBubble({required this.post, required this.onTap});

  final PostEntity post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.35),
                    AppTheme.cosmicPurple.withValues(alpha: 0.5),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: UserAvatar(
                  url: post.author.avatarUrl,
                  radius: 30,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              post.author.display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Canlı yayınlar: önce «Yayın başlat», sonra yayınlar ve boş slotlar.
class FeedLiveStrip extends ConsumerWidget {
  const FeedLiveStrip({super.key});

  static const int _maxLive = 8;
  static const int _emptySlots = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);
    return live.when(
      loading: () => GlowPanel(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accent.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (streams) {
        final onAir = streams.where((s) => s.isLive).toList();
        final n = onAir.length > _maxLive ? _maxLive : onAir.length;
        final total = 1 + n + _emptySlots;

        return GlowPanel(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CosmicSectionHeader(
                title: 'Canlı yayınlar',
                trailing: TextButton(
                  onPressed: () => context.go('/live'),
                  child: const Text('Tümünü gör'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 138,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: total,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return const _StartBroadcastCard();
                    }
                    if (i <= n) {
                      return _LiveChip(stream: onAir[i - 1]);
                    }
                    return const _EmptyLiveSlot();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StartBroadcastCard extends StatelessWidget {
  const _StartBroadcastCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/live'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppTheme.fabGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 42),
              SizedBox(height: 6),
              Text(
                'Yayın başlat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLiveSlot extends StatelessWidget {
  const _EmptyLiveSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surfaceElevated.withValues(alpha: 0.85),
        border: Border.all(
          color: AppTheme.cosmicPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_outlined,
            size: 36,
            color: AppTheme.muted.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 6),
          Text(
            'Boş slot',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.stream});

  final LiveStreamEntity stream;

  void _open(BuildContext context) {
    if (!stream.isLive) return;
    context.push(
      CanlifalWebRoute.location(
        relativePath: '/sohbet/video?watch=${stream.id}',
        title: stream.title,
        streamIdForGifts: stream.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: stream.isLive ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 118,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      stream.thumbnailUrl != null &&
                              stream.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              stream.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const ColoredBox(
                                color: AppTheme.surface,
                                child: Icon(Icons.live_tv_rounded,
                                    color: AppTheme.accent, size: 36),
                              ),
                            )
                          : const ColoredBox(
                              color: AppTheme.surface,
                              child: Icon(Icons.live_tv_rounded,
                                  color: AppTheme.accent, size: 36),
                            ),
                      if (stream.isLive)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text(
                              'CANLI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.streamerName ?? 'Yayıncı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${stream.viewerCount} izleyici',
                      style: TextStyle(
                        color: AppTheme.muted.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

/// Site ile aynı sesli sohbet odaları (`/api/chat/rooms`) — dairesel kartlar.
class FeedVoiceRoomsStrip extends ConsumerWidget {
  const FeedVoiceRoomsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) return const SizedBox.shrink();
    final rooms = ref.watch(voiceRoomsProvider);
    return rooms.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GlowPanel(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CosmicSectionHeader(
                  title: 'Sesli sohbet odaları',
                  trailing: TextButton(
                    onPressed: () => context.push('/voice-rooms'),
                    child: const Text('Tüm odalar'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (ctx, i) => _VoiceRoomCircle(room: list[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VoiceRoomCircle extends StatelessWidget {
  const _VoiceRoomCircle({required this.room});

  final VoiceRoomEntity room;

  void _open(BuildContext context) {
    context.push(
      CanlifalWebRoute.location(
        relativePath: '/sohbet/${room.slug}',
        title: room.nameTr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.cosmicPurple.withValues(alpha: 0.75),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: bg != null && bg.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: bg,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    _roomCircleFallback(room),
                              )
                            : _roomCircleFallback(room),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.cosmicPurple,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              room.nameTr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
            Text(
              '${room.onlineCount} kişi',
              style: TextStyle(
                fontSize: 9.5,
                color: AppTheme.muted.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomCircleFallback(VoiceRoomEntity r) {
    return ColoredBox(
      color: AppTheme.surfaceElevated,
      child: Center(
        child: Text(
          r.icon ?? '💬',
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

/// Akıştaki medyalı gönderilerle yatay «trend» önizleme.
class FeedTrendVideosStrip extends ConsumerWidget {
  const FeedTrendVideosStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedNotifierProvider);
    return feed.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (posts) {
        final withMedia =
            posts.where((p) => p.mediaUrl != null && p.mediaUrl!.isNotEmpty).take(10).toList();
        if (withMedia.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GlowPanel(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CosmicSectionHeader(
                  title: 'Trend videolar',
                  trailing: TextButton(
                    onPressed: () => context.go('/social'),
                    child: const Text('Tümü'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 188,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: withMedia.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) => _TrendVideoCard(post: withMedia[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrendVideoCard extends StatelessWidget {
  const _TrendVideoCard({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final tag = post.fortuneType != null && post.fortuneType!.isNotEmpty
        ? post.fortuneType!.replaceAll('-', ' ')
        : 'Video';
    return InkWell(
      onTap: () => context.push('/user/${post.author.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 152,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppTheme.surfaceElevated,
          border: Border.all(
            color: AppTheme.cosmicPurple.withValues(alpha: 0.4),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: AppTheme.surface,
                        child: Icon(Icons.play_circle_outline_rounded,
                            size: 48, color: AppTheme.muted.withValues(alpha: 0.5)),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 52,
                      child: _TrendMediaMetaChip(post: post),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.sectionBar.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.82),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.caption?.trim().isNotEmpty == true
                                  ? post.caption!.trim()
                                  : post.author.display,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.75)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    post.author.display,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

/// Trend kartında süre (API) veya görüntülenme sayısı.
class _TrendMediaMetaChip extends StatelessWidget {
  const _TrendMediaMetaChip({required this.post});

  final PostEntity post;

  static String _formatDuration(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dur = post.durationSeconds;
    final views = post.viewCount;
    if (dur != null && dur > 0) {
      return _trendMetaPill(
        icon: Icons.schedule_rounded,
        label: _formatDuration(dur),
      );
    }
    if (views > 0) {
      return _trendMetaPill(
        icon: Icons.visibility_rounded,
        label: NumberFormat.compact(locale: 'tr_TR').format(views),
      );
    }
    return const SizedBox.shrink();
  }

  static Widget _trendMetaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
