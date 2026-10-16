import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/providers/auth_selectors.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';
import '../../../../shorts/domain/entities/short_video_entity.dart';
import '../../../../shorts/presentation/providers/shorts_providers.dart';
import '../../../../shorts/presentation/utils/short_video_player_util.dart';
import '../../../../shorts/presentation/widgets/short_comments_sheet.dart';
import '../../../../shorts/presentation/widgets/short_share_sheet.dart';
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../models/social_feed_item.dart';
import '../../services/social_feed_ad_service.dart';
import '../instagram/double_tap_heart.dart';
import 'social_house_ad.dart';
import 'social_live_badge.dart';
import 'social_reel_item.dart';

/// Tam ekran dikey akış — her kaydırmada tek öğe: paylaşım, video, canlı yayın,
/// sesli oda veya reklam (AdMob geçiş reklamı; yoksa site tanıtımı).
class SocialFeedViewer extends ConsumerStatefulWidget {
  const SocialFeedViewer({
    super.key,
    required this.items,
    required this.visible,
    required this.topInset,
    required this.bottomInset,
    this.onLoadMore,
    this.onRefresh,
    this.initialIndex = 0,
    this.emptyBuilder,
  });

  final List<SocialFeedItem> items;
  final bool visible;
  final double topInset;
  final double bottomInset;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;
  final int initialIndex;
  final WidgetBuilder? emptyBuilder;

  @override
  ConsumerState<SocialFeedViewer> createState() => _SocialFeedViewerState();
}

class _SocialFeedViewerState extends ConsumerState<SocialFeedViewer>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  final Set<String> _removed = {};
  var _adShowing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(SocialFeedAdService.instance.preload(ref.read(dioProvider)));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<SocialFeedItem> get _items =>
      widget.items.where((e) => !_removed.contains(e.key)).toList();

  Future<void> _onAdActive(int index) async {
    if (_adShowing) return;
    setState(() => _adShowing = true);
    bool shown = false;
    try {
      shown = await SocialFeedAdService.instance
          .showIfReady(ref.read(dioProvider), ignoreInterval: true);
    } finally {
      if (mounted) setState(() => _adShowing = false);
    }
    // AdMob reklamı gösterildiyse kapandıktan sonra sıradaki içeriğe geç;
    // gösterilemediyse site reklamı sayfası ekranda kalır.
    if (shown && mounted && _pages.hasClients && index == _index) {
      unawaited(_pages.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _items;
    if (items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(
            child: Text('Henüz içerik yok',
                style: TextStyle(color: Colors.white70)),
          );
    }
    final idx = _index.clamp(0, items.length - 1);
    final view = PageView.builder(
      controller: _pages,
      scrollDirection: Axis.vertical,
      itemCount: items.length,
      onPageChanged: (i) {
        setState(() => _index = i);
        if (i >= items.length - 4) widget.onLoadMore?.call();
        if (widget.visible && items[i] is AdFeedItem) unawaited(_onAdActive(i));
      },
      itemBuilder: (context, i) {
        final it = items[i];
        final active = widget.visible && !_adShowing && i == idx;
        return switch (it) {
          PostFeedItem(:final post) => SocialReelItem(
              key: ValueKey(it.key),
              post: post,
              active: active,
              topInset: widget.topInset,
              bottomInset: widget.bottomInset,
              onChanged: (_) {},
              onRemoved: () => setState(() => _removed.add(it.key)),
            ),
          ShortFeedItem(:final video) => _ShortReel(
              key: ValueKey(it.key),
              video: video,
              active: active,
              bottomInset: widget.bottomInset,
            ),
          LiveFeedItem(:final stream) => _LiveReel(
              key: ValueKey(it.key),
              stream: stream,
              bottomInset: widget.bottomInset,
            ),
          RoomFeedItem(:final room) => _RoomReel(
              key: ValueKey(it.key),
              room: room,
              bottomInset: widget.bottomInset,
            ),
          AdFeedItem(:final slot) => SocialHouseAdPage(
              key: ValueKey(it.key),
              promo: housePromoFor(slot),
              topInset: widget.topInset,
              bottomInset: widget.bottomInset,
            ),
        };
      },
    );
    final refresh = widget.onRefresh;
    if (refresh == null) return view;
    return RefreshIndicator(
      onRefresh: refresh,
      edgeOffset: widget.topInset + 40,
      child: view,
    );
  }
}

/// Kısa video (trend) — tam ekran, sesli, döngü; sağ rayda beğeni/yorum/paylaş.
class _ShortReel extends ConsumerStatefulWidget {
  const _ShortReel({
    super.key,
    required this.video,
    required this.active,
    required this.bottomInset,
  });

  final ShortVideoEntity video;
  final bool active;
  final double bottomInset;

  @override
  ConsumerState<_ShortReel> createState() => _ShortReelState();
}

class _ShortReelState extends ConsumerState<_ShortReel> {
  VideoPlayerController? _c;
  var _loading = false;
  var _paused = false;
  var _heart = 0;
  late ShortVideoEntity _v = widget.video;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ShortReel old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _sync() {
    if (widget.active) {
      _paused = false;
      if (_c == null) {
        unawaited(_init());
      } else {
        unawaited(_c!.play());
      }
    } else {
      final c = _c;
      _c = null;
      if (c != null) {
        // İzlenme: ekrandan çıkarken izlenen süreyle kaydedilir.
        final sec = c.value.position.inMilliseconds / 1000;
        if (sec >= 1) {
          unawaited(ref
              .read(shortsRepositoryProvider)
              .recordView(_v.id, watchedSec: sec)
              .then((_) {}, onError: (_) {}));
        }
        unawaited(c.dispose());
      }
    }
  }

  Future<void> _init() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final c = await createShortVideoController(
        url: _v.videoUrl,
        videoId: _v.id,
        dio: ref.read(dioProvider),
      );
      if (!mounted || !widget.active) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.play();
      setState(() => _c = c);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _like() async {
    if (ref.read(currentUserIdProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beğenmek için giriş yapın')),
      );
      return;
    }
    final prev = _v;
    setState(() => _v = _v.copyWith(
          likedByMe: !_v.likedByMe,
          likesCount: (_v.likesCount + (_v.likedByMe ? -1 : 1)).clamp(0, 1 << 31),
        ));
    try {
      final r = await ref.read(shortsRepositoryProvider).toggleLike(_v.id);
      if (mounted) {
        setState(() => _v = _v.copyWith(likedByMe: r.liked, likesCount: r.likesCount));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _v = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  Future<void> _share() async {
    await showShortShareSheet(
      context,
      videoId: _v.id,
      description: _v.description,
      video: _v,
      ref: ref,
      onShared: () async {
        try {
          final n = await ref.read(shortsRepositoryProvider).recordShare(_v.id);
          if (mounted) {
            setState(() => _v = _v.copyWith(sharesCount: n > 0 ? n : _v.sharesCount + 1));
          }
        } catch (_) {}
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    Widget media;
    if (c != null && c.value.isInitialized) {
      final s = c.value.size;
      final ar = s.height == 0 ? 9 / 16 : s.width / s.height;
      media = FittedBox(
        fit: ar < 0.75 ? BoxFit.cover : BoxFit.contain,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: s.width, height: s.height, child: VideoPlayer(c)),
      );
    } else {
      final thumb = _v.displayThumbnailUrl;
      media = Stack(
        fit: StackFit.expand,
        children: [
          if (thumb != null && thumb.isNotEmpty)
            CanlifalNetworkImage(url: thumb, fit: BoxFit.cover),
          const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
          ),
        ],
      );
    }
    final author = _v.author;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final cc = _c;
              if (cc == null) return;
              setState(() {
                _paused = !_paused;
                _paused ? cc.pause() : cc.play();
              });
            },
            onDoubleTap: () {
              setState(() => _heart++);
              if (!_v.likedByMe) unawaited(_like());
            },
            child: media,
          ),
          const IgnorePointer(child: _BottomShade()),
          if (_paused)
            const IgnorePointer(
              child: Center(
                child: Icon(Icons.play_arrow_rounded, size: 84, color: Color(0xCCFFFFFF)),
              ),
            ),
          IgnorePointer(child: Center(child: DoubleTapHeart(token: _heart))),
          Positioned(
            right: 8,
            bottom: widget.bottomInset + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: author == null ? null : () => context.push('/user/${author.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: UserAvatar(url: author?.avatarUrl, radius: 22),
                  ),
                ),
                const SizedBox(height: 18),
                _Rail(
                  icon: Icons.favorite_rounded,
                  color: _v.likedByMe ? const Color(0xFFFE2C55) : Colors.white,
                  label: formatSocialCount(_v.likesCount),
                  onTap: _like,
                ),
                _Rail(
                  icon: Icons.chat_bubble_rounded,
                  label: formatSocialCount(_v.commentsCount),
                  onTap: () => showShortCommentsSheet(
                    context,
                    ref,
                    _v,
                    onCountChanged: (n) {
                      if (mounted) setState(() => _v = _v.copyWith(commentsCount: n));
                    },
                  ),
                ),
                _Rail(
                  icon: Icons.reply_rounded,
                  label: formatSocialCount(_v.sharesCount),
                  onTap: _share,
                ),
                _Rail(
                  icon: Icons.open_in_full_rounded,
                  label: 'Videolar',
                  onTap: () => context.push('/shorts?videoId=${_v.id}'),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 84,
            bottom: widget.bottomInset + 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF8A00), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Trend video · ${formatSocialCount(_v.viewsCount)} izlenme',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  author?.label ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                  ),
                ),
                if ((_v.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _v.description!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Açık canlı yayın kartı — dokununca yayına girer.
class _LiveReel extends ConsumerWidget {
  const _LiveReel({super.key, required this.stream, required this.bottomInset});

  final LiveStreamEntity stream;
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = stream.thumbnailUrl ?? stream.hostAvatarUrl;
    return GestureDetector(
      onTap: () => openLiveStreamNative(context, ref, stream),
      child: _JoinCard(
        cover: cover,
        avatar: stream.hostAvatarUrl ?? stream.thumbnailUrl,
        badge: SocialLiveBadge(fontSize: 14, viewers: stream.viewerCount),
        title: stream.streamerName?.trim().isNotEmpty == true
            ? stream.streamerName!
            : stream.title,
        subtitle: stream.title,
        cta: 'Canlı yayını izle',
        ctaIcon: Icons.play_circle_fill_rounded,
        bottomInset: bottomInset,
      ),
    );
  }
}

/// Sesli oda kartı — dokununca odaya girer.
class _RoomReel extends ConsumerWidget {
  const _RoomReel({super.key, required this.room, required this.bottomInset});

  final VoiceRoomEntity room;
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => openVoiceRoomWithVipGate(context, ref, room),
      child: _JoinCard(
        cover: room.backgroundImageUrl,
        avatar: room.ownerAvatarUrl ?? room.backgroundImageUrl,
        badge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '🎙 Sesli oda · ${room.displayOnline} kişi',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        title: room.displayTitle,
        subtitle: room.descTr ?? '',
        cta: 'Odaya katıl',
        ctaIcon: Icons.mic_rounded,
        bottomInset: bottomInset,
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.cover,
    required this.avatar,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.ctaIcon,
    required this.bottomInset,
  });

  final String? cover;
  final String? avatar;
  final Widget badge;
  final String title;
  final String subtitle;
  final String cta;
  final IconData ctaIcon;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover != null && cover!.trim().isNotEmpty)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Opacity(
                opacity: 0.6,
                child: CanlifalNetworkImage(url: cover!, fit: BoxFit.cover),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B0764), Color(0xFF0B0B12), Color(0xFF7F1D1D)],
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset * 0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFE2C55), Color(0xFFFF8A00), Color(0xFFB832FF)],
                      ),
                    ),
                    child: UserAvatar(url: avatar, radius: 64),
                  ),
                  const SizedBox(height: 14),
                  badge,
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty && subtitle != title) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFE2C55), Color(0xFFFF5F6D)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ctaIcon, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          cta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomShade extends StatelessWidget {
  const _BottomShade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.16, 0.62, 1],
          colors: [
            Color(0x8C000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0xB3000000),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            Icon(icon, size: 34, color: color,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 8)]),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
