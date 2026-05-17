import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ContentPost> _posts = <ContentPost>[];
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextPage());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<StoryItem>> stories = ref.watch(storiesProvider);
    final AsyncValue<List<LiveStream>> liveStreams = ref.watch(
      liveStreamsProvider,
    );

    return ResponsiveMaxWidth(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _PremiumHero(
                  onPremiumTap: () {
                    ref.read(authControllerProvider).activatePremium();
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Hikâyeler',
                subtitle: 'Canlı falcılar, ünlü profiller ve FanClub anları',
              ),
            ),
            SliverToBoxAdapter(
              child: stories.when(
                data: (List<StoryItem> items) => SizedBox(
                  height: 116,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (BuildContext context, int index) {
                      final StoryItem story = items[index];
                      return _StoryBubble(story: story);
                    },
                  ),
                ),
                loading: () => const SizedBox(
                  height: 116,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, StackTrace stackTrace) => Text('$error'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Öne çıkan canlılar',
                actionLabel: 'Tümü',
              ),
            ),
            SliverToBoxAdapter(
              child: liveStreams.when(
                data: (List<LiveStream> streams) => SizedBox(
                  height: 230,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: streams.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: 14),
                    itemBuilder: (BuildContext context, int index) {
                      return _LivePreviewCard(stream: streams[index]);
                    },
                  ),
                ),
                loading: () => const SizedBox(
                  height: 230,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, StackTrace stackTrace) => Text('$error'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Sonsuz akış',
                subtitle:
                    'Trend içerikler, son paylaşımlar ve sosyal etkileşim',
              ),
            ),
            SliverList.separated(
              itemCount: _posts.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 14),
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PostCard(post: _posts[index]),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _hasMore
                              ? 'Daha fazla içerik için kaydır'
                              : 'Akış güncel',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 420 &&
        !_isLoading &&
        _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _page = 0;
      _hasMore = true;
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoading = true);
    final CanlifalRepository repository = await ref.read(
      canlifalRepositoryProvider.future,
    );
    final List<ContentPost> pageItems = await repository.getFeedPage(_page);
    if (!mounted) {
      return;
    }
    setState(() {
      _posts.addAll(pageItems);
      _page += 1;
      _hasMore = pageItems.isNotEmpty && _page < 8;
      _isLoading = false;
    });
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.onPremiumTap});

  final VoidCallback onPremiumTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Canlifal Premium',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'FanClub, özel yayınlar, rozetler, coin bonusları ve öncelikli fal sırası.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: onPremiumTap,
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Yükselt'),
          ),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story});

  final StoryItem story;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: <Widget>[
          GradientAvatar(
            imageUrl: story.imageUrl,
            radius: 31,
            isLive: story.isLive,
          ),
          const SizedBox(height: 8),
          Text(
            story.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({required this.stream});

  final LiveStream stream;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: () => context.go('/live/${stream.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CachedNetworkImage(
                imageUrl: stream.thumbnailUrl,
                fit: BoxFit.cover,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: StatPill(
                icon: Icons.visibility,
                label: 'izleyici',
                value: compactNumber(stream.viewers),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    stream.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      GradientAvatar(
                        imageUrl: stream.host.avatarUrl,
                        radius: 14,
                        isLive: true,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stream.host.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                GradientAvatar(imageUrl: post.author.avatarUrl, radius: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        post.author.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '@${post.author.username} · ${post.createdLabel}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(imageUrl: post.mediaUrl, fit: BoxFit.cover),
                if (post.isVideo)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: .45),
                      ),
                      child: const Icon(Icons.play_arrow, size: 42),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(post.caption),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final String hashtag in post.hashtags)
                      Text(
                        hashtag,
                        style: const TextStyle(color: Color(0xFF22D3EE)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    _Action(
                      icon: Icons.favorite_border,
                      label: compactNumber(post.likes),
                    ),
                    _Action(
                      icon: Icons.mode_comment_outlined,
                      label: compactNumber(post.comments),
                    ),
                    _Action(
                      icon: Icons.bookmark_border,
                      label: compactNumber(post.saves),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: () {},
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('Hediye'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
