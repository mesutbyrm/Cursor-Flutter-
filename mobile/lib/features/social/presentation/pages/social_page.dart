import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../feed/domain/entities/post_entity.dart';
import '../providers/social_reels_provider.dart';
import '../widgets/reels/social_reel_item.dart';

/// GirLive Sosyal — TikTok tarzı tam ekran akış.
///
/// Üst bar: **Canlı** · **Keşfet** · **Takip Ettiğin** · arama. Keşfet tüm
/// paylaşımları (yazı, görsel, video), Takip Ettiğin yalnız takip edilenleri
/// gösterir. Her kaydırmada bir paylaşım, ekrana sığdırılmış olarak gelir.
class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage>
    with WidgetsBindingObserver {
  static const _feeds = ['all', 'following'];

  final _tabs = PageController();
  var _tab = 0;
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
    if (active) {
      // Her açılışta yeni paylaşımlar.
      unawaited(ref.read(socialReelsProvider(_feeds[_tab]).notifier).refresh());
    }
  }

  void _selectTab(int i) {
    if (i == _tab) {
      unawaited(ref.read(socialReelsProvider(_feeds[i]).notifier).refresh());
      return;
    }
    _tabs.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    // Alt gezinme çubuğu akışın üstünde durur.
    final bottomInset = mq.padding.bottom + 88;
    // Başka sekmeye geçildiğinde / üstüne sayfa açıldığında video durur.
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
                for (var i = 0; i < _feeds.length; i++)
                  _ReelsFeed(
                    feed: _feeds[i],
                    visible: visible && _tab == i,
                    topInset: topInset,
                    bottomInset: bottomInset,
                    onGoExplore: () => _selectTab(0),
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _ReelsTopBar(
                topInset: topInset,
                selected: _tab,
                onLive: () => context.go('/live'),
                onTab: _selectTab,
                onSearch: () => context.push('/search'),
                onCreate: () => context.push('/social/create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TikTok üst barı: solda Canlı, ortada Keşfet / Takip Ettiğin, sağda arama.
class _ReelsTopBar extends StatelessWidget {
  const _ReelsTopBar({
    required this.topInset,
    required this.selected,
    required this.onLive,
    required this.onTab,
    required this.onSearch,
    required this.onCreate,
  });

  final double topInset;
  final int selected;
  final VoidCallback onLive;
  final ValueChanged<int> onTab;
  final VoidCallback onSearch;
  final VoidCallback onCreate;

  static const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 6)];

  static TextStyle style(bool active) => TextStyle(
        color: active ? Colors.white : const Color(0xB3FFFFFF),
        fontSize: 17,
        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: -0.2,
        shadows: _shadow,
      );

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, int i) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTab(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: style(selected == i)),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected == i ? 26 : 0,
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

    return Padding(
      padding: EdgeInsets.fromLTRB(8, topInset + 6, 4, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLive,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 14),
              child: Text('Canlı', style: style(false)),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  tab('Keşfet', 0),
                  tab('Takip Ettiğin', 1),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Paylaşım yap',
            onPressed: onCreate,
            icon: const Icon(Icons.add_box_outlined,
                color: Colors.white, size: 26, shadows: _shadow),
          ),
          IconButton(
            tooltip: 'Ara',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded,
                color: Colors.white, size: 30, shadows: _shadow),
          ),
        ],
      ),
    );
  }
}

class _ReelsFeed extends ConsumerStatefulWidget {
  const _ReelsFeed({
    required this.feed,
    required this.visible,
    required this.topInset,
    required this.bottomInset,
    required this.onGoExplore,
  });

  final String feed;
  final bool visible;
  final double topInset;
  final double bottomInset;
  final VoidCallback onGoExplore;

  @override
  ConsumerState<_ReelsFeed> createState() => _ReelsFeedState();
}

class _ReelsFeedState extends ConsumerState<_ReelsFeed>
    with AutomaticKeepAliveClientMixin {
  final _pages = PageController();
  var _index = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  SocialReelsNotifier get _notifier =>
      ref.read(socialReelsProvider(widget.feed).notifier);

  Future<void> _refresh() async {
    await _notifier.refresh();
    if (_pages.hasClients) _pages.jumpToPage(0);
    if (mounted) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final async = ref.watch(socialReelsProvider(widget.feed));
    final posts = async.valueOrNull;

    if (posts == null) {
      if (async.hasError) {
        return _Message(
          icon: Icons.wifi_off_rounded,
          text: 'Paylaşımlar yüklenemedi.',
          action: 'Tekrar dene',
          onAction: () => ref.invalidate(socialReelsProvider(widget.feed)),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
      );
    }
    if (posts.isEmpty) {
      final following = widget.feed == 'following';
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.8,
              child: _Message(
                icon: following
                    ? Icons.people_outline_rounded
                    : Icons.photo_library_outlined,
                text: following
                    ? 'Takip ettiğin kişilerin henüz paylaşımı yok.'
                    : 'Henüz paylaşım yok.',
                action: following ? 'Keşfet\'e geç' : 'Yenile',
                onAction: following ? widget.onGoExplore : _refresh,
              ),
            ),
          ],
        ),
      );
    }

    final idx = _index.clamp(0, posts.length - 1);
    return RefreshIndicator(
      onRefresh: _refresh,
      edgeOffset: widget.topInset + 40,
      child: PageView.builder(
        controller: _pages,
        scrollDirection: Axis.vertical,
        itemCount: posts.length,
        onPageChanged: (i) {
          setState(() => _index = i);
          if (i >= posts.length - 3) unawaited(_notifier.loadMore());
        },
        itemBuilder: (context, i) {
          final PostEntity p = posts[i];
          return SocialReelItem(
            key: ValueKey('reel-${widget.feed}-${p.id}'),
            post: p,
            active: widget.visible && i == idx,
            topInset: widget.topInset,
            bottomInset: widget.bottomInset,
            onChanged: _notifier.updatePost,
            onRemoved: () => _notifier.removePost(p.id),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 56),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
