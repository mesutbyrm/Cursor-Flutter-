import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../../live/presentation/utils/open_live_stream.dart';
import '../../../shorts/domain/entities/short_video_entity.dart';
import '../../../shorts/domain/repositories/shorts_repository.dart';
import '../../../shorts/presentation/providers/shorts_explore_providers.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../models/social_feed_item.dart';
import '../providers/social_reels_provider.dart';
import '../widgets/instagram/social_post_video_player.dart'
    show socialPostLooksLikeVideo;
import '../widgets/reels/social_feed_viewer.dart';
import '../widgets/reels/social_fortune_page.dart';
import '../widgets/reels/social_house_ad.dart';
import '../widgets/reels/social_live_badge.dart';

/// GirLive Sosyal.
///
/// Üst bar: **Canlı** · **Keşfet** · **Video** · **Takipte**, sağda ＋ ve arama.
/// - Canlı: yayındaki kişiler (profil resmi, izleyici sayısı, yanıp sönen CANLI).
/// - Keşfet: Instagram Keşfet gibi en çok izlenen canlılar, videolar, odalar ve
///   paylaşımlar; dokununca tam ekran akış (paylaşımlar arasında trend videolar
///   ve açık canlı yayınlar).
/// - Video: yalnız videolar, tam ekran.
/// - Takipte: takip ettiklerinin Videoları / Paylaşımları.
/// Her 5 içerikten sonra geçiş reklamı; yoksa site tanıtımı.
class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage>
    with WidgetsBindingObserver {
  static const _tabLabels = ['Canlı', 'Keşfet', 'Video', 'Takipte'];
  final _tabs = PageController(initialPage: 1);
  var _tab = 1;
  var _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active != _appActive) setState(() => _appActive = active);
    if (active) unawaited(_refreshTab(_tab));
  }

  Future<void> _refreshTab(int i) async {
    switch (i) {
      case 0:
        await ref.read(liveStreamsListNotifierProvider.notifier).refresh();
      case 1:
        await Future.wait([
          ref.read(socialReelsProvider('all').notifier).refresh(),
          ref.read(liveStreamsListNotifierProvider.notifier).refresh(),
          ref.read(shortsExploreProvider.notifier).refresh(),
        ]);
      case 2:
        await ref.read(shortsFeedProvider(ShortsFeedTab.forYou).notifier).refresh();
      case 3:
        await Future.wait([
          ref.read(socialReelsProvider('following').notifier).refresh(),
          ref.read(shortsFeedProvider(ShortsFeedTab.following).notifier).refresh(),
        ]);
    }
  }

  void _selectTab(int i) {
    if (i == _tab) {
      unawaited(_refreshTab(i));
      return;
    }
    _tabs.animateToPage(i,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  Future<void> _create() async {
    await context.push('/social/create');
    if (mounted) unawaited(ref.read(socialReelsProvider('all').notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final bottomInset = mq.padding.bottom + 88;
    final visible = TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        _appActive;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView(
              controller: _tabs,
              onPageChanged: (i) => setState(() => _tab = i),
              children: [
                _LiveTab(topInset: topInset, bottomInset: bottomInset,
                    onExplore: () => _selectTab(1)),
                _ExploreTab(topInset: topInset, bottomInset: bottomInset),
                _VideoTab(
                  visible: visible && _tab == 2,
                  topInset: topInset,
                  bottomInset: bottomInset,
                ),
                _FollowingTab(
                  visible: visible && _tab == 3,
                  topInset: topInset,
                  bottomInset: bottomInset,
                  onExplore: () => _selectTab(1),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _TopBar(
                topInset: topInset,
                labels: _tabLabels,
                selected: _tab,
                onTab: _selectTab,
                onSearch: () => context.push('/search'),
                onCreate: _create,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.topInset,
    required this.labels,
    required this.selected,
    required this.onTab,
    required this.onSearch,
    required this.onCreate,
  });

  final double topInset;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onTab;
  final VoidCallback onSearch;
  final VoidCallback onCreate;

  static const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 6)];

  @override
  Widget build(BuildContext context) {
    Widget tab(int i) {
      final active = selected == i;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTab(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i == 0) ...[
                    const _PulseDot(),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xB3FFFFFF),
                      fontSize: 17,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: -0.2,
                      shadows: _shadow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 24 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(4, topInset + 4, 4, 2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99000000), Color(0x00000000)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (var i = 0; i < labels.length; i++) tab(i)],
              ),
            ),
          ),
          GestureDetector(onTap: onCreate, child: const SocialPlusButton()),
          IconButton(
            tooltip: 'Ara',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded,
                color: Colors.white, size: 28, shadows: _shadow),
          ),
        ],
      ),
    );
  }
}

/// TikTok tarzı ＋ (turkuaz/pembe gölgeli beyaz kart).
class SocialPlusButton extends StatelessWidget {
  const SocialPlusButton({super.key, this.width = 40, this.height = 28});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(9);
    return Semantics(
      button: true,
      label: 'Paylaşım yap',
      child: SizedBox(
        width: width + 8,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(color: const Color(0xFF25F4EE), borderRadius: r),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(color: const Color(0xFFFE2C55), borderRadius: r),
              ),
            ),
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(color: Colors.white, borderRadius: r),
              child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Color(0xFFFE2C55), shape: BoxShape.circle),
      ),
    );
  }
}

// ───────────────────────────── Canlı ─────────────────────────────

class _LiveTab extends ConsumerWidget {
  const _LiveTab({
    required this.topInset,
    required this.bottomInset,
    required this.onExplore,
  });

  final double topInset;
  final double bottomInset;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(liveStreamsListNotifierProvider);
    final lives = (async.valueOrNull ?? const <LiveStreamEntity>[])
        .where((s) => s.isLive)
        .toList()
      ..sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
    Future<void> refresh() =>
        ref.read(liveStreamsListNotifierProvider.notifier).refresh();

    if (async.isLoading && lives.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2));
    }
    if (lives.isEmpty) {
      final rooms = (ref.watch(voiceRoomsListNotifierProvider).valueOrNull ??
              const <VoiceRoomEntity>[])
          .where((r) => r.displayOnline > 0)
          .take(6)
          .toList();
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topInset + 70, 16, bottomInset + 16),
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 64),
            const SizedBox(height: 14),
            const Text(
              'Şu an canlı yayında kimse yok',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Yayın başlayınca burada görünür. Bu arada sesli odalara katılabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(onPressed: onExplore, child: const Text('Keşfet\'e geç')),
            ),
            if (rooms.isNotEmpty) ...[
              const SizedBox(height: 26),
              const Text('🎙 Aktif sesli odalar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              for (final r in rooms)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(url: r.ownerAvatarUrl ?? r.backgroundImageUrl, radius: 22),
                  title: Text(r.displayTitle, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${r.displayOnline} kişi içeride',
                      style: const TextStyle(color: Colors.white60)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  onTap: () => openVoiceRoomWithVipGate(context, ref, r),
                ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: refresh,
      edgeOffset: topInset + 50,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(10, topInset + 64, 10, bottomInset + 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: lives.length,
        itemBuilder: (context, i) => _LiveTile(stream: lives[i]),
      ),
    );
  }
}

class _LiveTile extends ConsumerWidget {
  const _LiveTile({required this.stream});

  final LiveStreamEntity stream;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = stream.hostAvatarUrl ?? stream.thumbnailUrl;
    final cover = stream.thumbnailUrl ?? stream.hostAvatarUrl;
    final name = stream.streamerName?.trim().isNotEmpty == true
        ? stream.streamerName!
        : stream.title;
    return GestureDetector(
      onTap: () => openLiveStreamNative(context, ref, stream),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover != null && cover.isNotEmpty)
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: CanlifalNetworkImage(url: cover, fit: BoxFit.cover),
              )
            else
              const ColoredBox(color: Color(0xFF1F1530)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xCC000000)],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFE2C55), Color(0xFFFF8A00), Color(0xFFB832FF)],
                    ),
                  ),
                  child: UserAvatar(url: avatar, radius: 40),
                ),
                const SizedBox(height: 10),
                SocialLiveBadge(fontSize: 12, viewers: stream.viewerCount),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (stream.title.trim().isNotEmpty && stream.title != name)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                    child: Text(
                      stream.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Keşfet ─────────────────────────────

/// Keşfet ızgarası kutusu.
sealed class _Tile {
  const _Tile();
}

class _ItemTile extends _Tile {
  const _ItemTile(this.item);
  final SocialFeedItem item;
}

class _PromoTile extends _Tile {
  const _PromoTile(this.seed);
  final int seed;
}

class _ExploreTab extends ConsumerWidget {
  const _ExploreTab({required this.topInset, required this.bottomInset});

  final double topInset;
  final double bottomInset;

  static int _postScore(PostEntity p) =>
      p.likesCount * 3 + p.commentsCount * 4 + p.displayViewCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(socialReelsProvider('all'));
    final posts = postsAsync.valueOrNull ?? const <PostEntity>[];
    final lives = [
      ...?ref.watch(liveStreamsListNotifierProvider).valueOrNull,
    ].where((s) => s.isLive).toList()
      ..sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
    final rooms = [
      ...?ref.watch(voiceRoomsListNotifierProvider).valueOrNull,
    ].where((r) => r.displayOnline > 0).toList()
      ..sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
    final shorts = [
      ...?ref.watch(shortsExploreProvider).valueOrNull?.videos,
    ]..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final rankedPosts = [...posts]
      ..sort((a, b) => _postScore(b).compareTo(_postScore(a)));

    if (posts.isEmpty && postsAsync.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2));
    }

    // En çok izlenen/etkileşim alanlar karışık: canlı, video, paylaşım, oda.
    final tiles = <_Tile>[];
    var li = 0, si = 0, pi = 0, ri = 0, n = 0;
    while (li < lives.length || si < shorts.length || pi < rankedPosts.length || ri < rooms.length) {
      if (li < lives.length && n % 4 == 0) tiles.add(_ItemTile(LiveFeedItem(lives[li++])));
      if (si < shorts.length) tiles.add(_ItemTile(ShortFeedItem(shorts[si++])));
      if (pi < rankedPosts.length) tiles.add(_ItemTile(PostFeedItem(rankedPosts[pi++])));
      if (pi < rankedPosts.length) tiles.add(_ItemTile(PostFeedItem(rankedPosts[pi++])));
      if (ri < rooms.length && n % 3 == 1) tiles.add(_ItemTile(RoomFeedItem(rooms[ri++])));
      n++;
      if (tiles.length % 11 == 10) tiles.add(_PromoTile(n));
    }
    if (tiles.isEmpty) {
      return const Center(
          child: Text('Henüz keşfedilecek içerik yok', style: TextStyle(color: Colors.white70)));
    }

    // Tam ekran akış: dokunulan içerikten başlayarak paylaşımlar + trend
    // videolar + açık canlılar; her 5 içerikte reklam.
    final viewerItems = withAdSlots(
      interleaveFeed(posts: rankedPosts, videos: shorts, lives: lives),
    );

    void open(SocialFeedItem it) {
      switch (it) {
        case LiveFeedItem(:final stream):
          openLiveStreamNative(context, ref, stream);
        case RoomFeedItem(:final room):
          openVoiceRoomWithVipGate(context, ref, room);
        default:
          final start = viewerItems.indexWhere((e) => e.key == it.key);
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _ExploreViewerPage(
              items: viewerItems,
              initialIndex: start < 0 ? 0 : start,
            ),
          ));
      }
    }

    // Instagram Keşfet ızgarası: 3 sütun; her grupta 1 büyük (2×2) kutu.
    final rows = <Widget>[];
    final w = MediaQuery.sizeOf(context).width;
    const gap = 2.0;
    final cell = (w - gap * 2) / 3;
    var i = 0;
    var group = 0;
    Widget tileAt(int k, {bool big = false}) {
      if (k >= tiles.length) return const SizedBox.shrink();
      final t = tiles[k];
      return switch (t) {
        _PromoTile(:final seed) => SocialHouseAdTile(promo: housePromoFor(seed)),
        _ItemTile(:final item) =>
          _ExploreCell(item: item, big: big, onTap: () => open(item)),
      };
    }

    while (i < tiles.length) {
      if (group.isEven && i + 2 < tiles.length) {
        final bigLeft = group % 4 == 0;
        final big = SizedBox(
          width: cell * 2 + gap,
          height: cell * 2 + gap,
          child: tileAt(i, big: true),
        );
        final col = Column(
          children: [
            SizedBox(width: cell, height: cell, child: tileAt(i + 1)),
            const SizedBox(height: gap),
            SizedBox(width: cell, height: cell, child: tileAt(i + 2)),
          ],
        );
        rows.add(Row(
          children: bigLeft
              ? [big, const SizedBox(width: gap), col]
              : [col, const SizedBox(width: gap), big],
        ));
        i += 3;
      } else {
        rows.add(Row(
          children: [
            for (var k = 0; k < 3; k++) ...[
              if (k > 0) const SizedBox(width: gap),
              SizedBox(width: cell, height: cell * 1.3, child: tileAt(i + k)),
            ],
          ],
        ));
        i += 3;
      }
      rows.add(const SizedBox(height: gap));
      group++;
    }

    return RefreshIndicator(
      edgeOffset: topInset + 50,
      onRefresh: () => Future.wait([
        ref.read(socialReelsProvider('all').notifier).refresh(),
        ref.read(liveStreamsListNotifierProvider.notifier).refresh(),
        ref.read(shortsExploreProvider.notifier).refresh(),
      ]),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) {
            unawaited(ref.read(socialReelsProvider('all').notifier).loadMore());
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.only(top: topInset + 58, bottom: bottomInset + 12),
          children: rows,
        ),
      ),
    );
  }
}

class _ExploreCell extends StatelessWidget {
  const _ExploreCell({required this.item, required this.onTap, this.big = false});

  final SocialFeedItem item;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    Widget bg;
    Widget? badge;
    String? caption;
    switch (item) {
      case LiveFeedItem(:final stream):
        bg = _img(stream.thumbnailUrl ?? stream.hostAvatarUrl);
        badge = SocialLiveBadge(fontSize: big ? 12 : 9, viewers: stream.viewerCount);
        caption = stream.streamerName ?? stream.title;
      case RoomFeedItem(:final room):
        bg = _img(room.backgroundImageUrl ?? room.ownerAvatarUrl);
        badge = _chip('🎙 ${room.displayOnline}', const Color(0xFF7C3AED));
        caption = room.displayTitle;
      case ShortFeedItem(:final video):
        bg = _img(video.displayThumbnailUrl);
        badge = _chip('▶ ${formatSocialCount(video.viewsCount)}', Colors.black54);
        caption = null;
      case PostFeedItem(:final post):
        final media = (post.mediaUrl ?? '').trim();
        final isVideo = media.isNotEmpty &&
            socialPostLooksLikeVideo(postType: post.postType, mediaUrl: media);
        if (post.isFortunePost && media.isEmpty) {
          final t = SocialFortunePage.resolveType(post);
          bg = _FortuneCellBg(slug: t.slug, accent: t.accent, title: t.title);
        } else if (media.isNotEmpty && !isVideo) {
          bg = _img(media);
        } else if (isVideo) {
          bg = _img(media);
          badge = _chip('▶', Colors.black54);
        } else {
          bg = _TextCellBg(text: post.caption ?? '', seed: post.id.hashCode);
        }
        if (post.likesCount > 0) {
          badge ??= _chip('❤ ${formatSocialCount(post.likesCount)}', Colors.black45);
        }
      case AdFeedItem():
        bg = const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: onTap,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            bg,
            if (badge != null) Positioned(left: 6, top: 6, child: badge),
            if (caption != null && caption.trim().isNotEmpty)
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _img(String? url) {
    if (url == null || url.trim().isEmpty) {
      return const ColoredBox(color: Color(0xFF1A1A22));
    }
    return CanlifalNetworkImage(url: url, fit: BoxFit.cover);
  }

  static Widget _chip(String text, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
      );
}

class _FortuneCellBg extends StatelessWidget {
  const _FortuneCellBg({required this.slug, required this.accent, required this.title});

  final String slug;
  final Color accent;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SocialFortuneCover(slug: slug, accent: accent),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xAA000000)],
            ),
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          child: Text(
            '🔮 $title',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _TextCellBg extends StatelessWidget {
  const _TextCellBg({required this.text, required this.seed});

  final String text;
  final int seed;

  static const _palettes = <List<Color>>[
    [Color(0xFF25F4EE), Color(0xFFFE2C55)],
    [Color(0xFF7C3AED), Color(0xFFDB2777)],
    [Color(0xFF0EA5E9), Color(0xFF22C55E)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];

  @override
  Widget build(BuildContext context) {
    final c = _palettes[seed.abs() % _palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c[0].withValues(alpha: 0.75), c[1].withValues(alpha: 0.75)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            text,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
        ),
      ),
    );
  }
}

class _ExploreViewerPage extends StatelessWidget {
  const _ExploreViewerPage({required this.items, required this.initialIndex});

  final List<SocialFeedItem> items;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SocialFeedViewer(
              items: items,
              initialIndex: initialIndex,
              visible: TickerMode.of(context),
              topInset: mq.padding.top,
              bottomInset: mq.padding.bottom + 12,
            ),
            Positioned(
              left: 4,
              top: mq.padding.top + 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Video ─────────────────────────────

class _VideoTab extends ConsumerWidget {
  const _VideoTab({
    required this.visible,
    required this.topInset,
    required this.bottomInset,
  });

  final bool visible;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsFeedProvider(ShortsFeedTab.forYou));
    final shorts = shortsAsync.valueOrNull ?? const <ShortVideoEntity>[];
    // Sosyal akışta paylaşılan videolar da (görsel/yazı hariç).
    final videoPosts = (ref.watch(socialReelsProvider('all')).valueOrNull ?? const <PostEntity>[])
        .where((p) =>
            (p.mediaUrl ?? '').trim().isNotEmpty &&
            socialPostLooksLikeVideo(postType: p.postType, mediaUrl: p.mediaUrl))
        .toList();
    if (shorts.isEmpty && videoPosts.isEmpty && shortsAsync.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2));
    }
    final items = <SocialFeedItem>[];
    var vp = 0;
    for (var i = 0; i < shorts.length; i++) {
      items.add(ShortFeedItem(shorts[i]));
      if (i % 3 == 2 && vp < videoPosts.length) items.add(PostFeedItem(videoPosts[vp++]));
    }
    while (vp < videoPosts.length) {
      items.add(PostFeedItem(videoPosts[vp++]));
    }
    return SocialFeedViewer(
      items: withAdSlots(items),
      visible: visible,
      topInset: topInset,
      bottomInset: bottomInset,
      onLoadMore: () =>
          ref.read(shortsFeedProvider(ShortsFeedTab.forYou).notifier).loadMore(),
      onRefresh: () =>
          ref.read(shortsFeedProvider(ShortsFeedTab.forYou).notifier).refresh(),
      emptyBuilder: (_) => const Center(
        child: Text('Henüz video yok', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}

// ───────────────────────────── Takipte ─────────────────────────────

class _FollowingTab extends ConsumerStatefulWidget {
  const _FollowingTab({
    required this.visible,
    required this.topInset,
    required this.bottomInset,
    required this.onExplore,
  });

  final bool visible;
  final double topInset;
  final double bottomInset;
  final VoidCallback onExplore;

  @override
  ConsumerState<_FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends ConsumerState<_FollowingTab> {
  var _videos = true;

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded, color: Colors.white54, size: 56),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 14),
              FilledButton(onPressed: widget.onExplore, child: const Text('Keşfet\'e geç')),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_videos) {
      final async = ref.watch(shortsFeedProvider(ShortsFeedTab.following));
      final list = async.valueOrNull ?? const <ShortVideoEntity>[];
      body = list.isEmpty && async.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2))
          : SocialFeedViewer(
              key: const ValueKey('following-videos'),
              items: withAdSlots([for (final v in list) ShortFeedItem(v)]),
              visible: widget.visible,
              topInset: widget.topInset + 44,
              bottomInset: widget.bottomInset,
              onLoadMore: () =>
                  ref.read(shortsFeedProvider(ShortsFeedTab.following).notifier).loadMore(),
              onRefresh: () =>
                  ref.read(shortsFeedProvider(ShortsFeedTab.following).notifier).refresh(),
              emptyBuilder: (_) => _empty('Takip ettiklerinin henüz videosu yok.'),
            );
    } else {
      final async = ref.watch(socialReelsProvider('following'));
      final list = async.valueOrNull ?? const <PostEntity>[];
      body = list.isEmpty && async.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2))
          : SocialFeedViewer(
              key: const ValueKey('following-posts'),
              items: withAdSlots([for (final p in list) PostFeedItem(p)]),
              visible: widget.visible,
              topInset: widget.topInset + 44,
              bottomInset: widget.bottomInset,
              onLoadMore: () =>
                  ref.read(socialReelsProvider('following').notifier).loadMore(),
              onRefresh: () =>
                  ref.read(socialReelsProvider('following').notifier).refresh(),
              emptyBuilder: (_) => _empty('Takip ettiklerinin henüz paylaşımı yok.'),
            );
    }
    Widget chip(String label, bool on, VoidCallback tap) => GestureDetector(
          onTap: tap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white54),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: on ? Colors.black : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        Positioned(
          top: widget.topInset + 54,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              chip('🎬 Videolar', _videos, () => setState(() => _videos = true)),
              const SizedBox(width: 10),
              chip('📝 Paylaşımlar', !_videos, () => setState(() => _videos = false)),
            ],
          ),
        ),
      ],
    );
  }
}
