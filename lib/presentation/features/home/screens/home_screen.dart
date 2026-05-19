import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_mobile/domain/entities/entities.dart';
import 'package:canlifal_mobile/domain/repositories/social_repository.dart';
import 'package:canlifal_mobile/presentation/providers/providers.dart';
import 'package:canlifal_mobile/presentation/widgets/shared_widgets.dart';

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
    final AsyncValue<List<ChatRoom>> chatRooms = ref.watch(chatRoomsProvider);
    final AsyncValue<List<FortuneService>> fortunes = ref.watch(
      fortuneServicesProvider,
    );

    return ResponsiveMaxWidth(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Hikâyeler', actionLabel: 'Tümü'),
            ),
            SliverToBoxAdapter(
              child: stories.when(
                data: (List<StoryItem> items) => SizedBox(
                  height: 112,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length + 1,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return const _AddStoryBubble();
                      }
                      final StoryItem story = items[index - 1];
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
                title: 'Canlı Yayınlar',
                actionLabel: 'Tümünü gör',
              ),
            ),
            SliverToBoxAdapter(
              child: liveStreams.when(
                data: (List<LiveStream> streams) =>
                    _LiveSlots(streams: streams.take(3).toList()),
                loading: () => const SizedBox(
                  height: 128,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, StackTrace stackTrace) => Text('$error'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Sesli Sohbet Odaları',
                actionLabel: 'Tüm Odalar',
              ),
            ),
            SliverToBoxAdapter(
              child: chatRooms.when(
                data: (List<ChatRoom> rooms) =>
                    _VoiceRooms(rooms: rooms.take(6).toList()),
                loading: () => const SizedBox(
                  height: 112,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, StackTrace stackTrace) => Text('$error'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: '▷ Trend Videolar',
                actionLabel: 'Tümü',
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
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Fal & Tarot',
                actionLabel: 'Tüm Fallar',
              ),
            ),
            SliverToBoxAdapter(child: _FortuneGrid()),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: '🔥 Popüler Falcılar',
                actionLabel: 'Tümünü gör',
              ),
            ),
            SliverToBoxAdapter(
              child: fortunes.when(
                data: (List<FortuneService> items) =>
                    _PopularTellers(items: items.take(6).toList()),
                loading: () => const SizedBox(
                  height: 128,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, StackTrace stackTrace) => Text('$error'),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(title: '◎ Keşfet')),
            const SliverToBoxAdapter(child: _ExploreGrid()),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: '♕ Gold Üyelikler',
                actionLabel: 'Tümünü gör',
              ),
            ),
            SliverToBoxAdapter(
              child: _GoldPlans(
                onTap: () => ref.read(authControllerProvider).activatePremium(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
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
    final SocialRepository repository = await ref.read(
      socialRepositoryProvider.future,
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

class _AddStoryBubble extends StatelessWidget {
  const _AddStoryBubble();

  @override
  Widget build(BuildContext context) {
    return CircleLogo(
      imageUrl: CanlifalAssets.avatarPlaceholder,
      label: 'Hikâye Ekle',
      badge: Icons.add,
      onTap: () {},
    );
  }
}

class _LiveSlots extends StatelessWidget {
  const _LiveSlots({required this.streams});

  final List<LiveStream> streams;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _LiveStartSlot(onTap: () => context.go('/live/create'));
          }
          final int streamIndex = index - 1;
          if (streamIndex < streams.length) {
            return _LiveSmallSlot(stream: streams[streamIndex]);
          }
          return const _EmptyLiveSlot();
        },
      ),
    );
  }
}

class _LiveStartSlot extends StatelessWidget {
  const _LiveStartSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFF43C7), Color(0xFF6D15A8)],
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_circle_outline, size: 44),
              SizedBox(height: 8),
              Text(
                'Yayın Başlat',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSmallSlot extends StatelessWidget {
  const _LiveSmallSlot({required this.stream});

  final LiveStream stream;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: () => context.go('/live/${stream.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: stream.thumbnailUrl,
                fit: BoxFit.cover,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black.withValues(alpha: .45),
              ),
            ),
            const Center(child: Icon(Icons.videocam, size: 34)),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                stream.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLiveSlot extends StatelessWidget {
  const _EmptyLiveSlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF3A0A55).withValues(alpha: .55),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.videocam_outlined, color: Color(0xFFFF72E0), size: 34),
              SizedBox(height: 12),
              Text('Boş Slot', style: TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceRooms extends StatelessWidget {
  const _VoiceRooms({required this.rooms});

  final List<ChatRoom> rooms;

  @override
  Widget build(BuildContext context) {
    final List<ChatRoom> visible = rooms.isEmpty ? const <ChatRoom>[] : rooms;
    return SizedBox(
      height: 116,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int index) {
          final ChatRoom room = visible[index];
          return CircleLogo(
            imageUrl: room.avatarUrl,
            label: room.name,
            subtitle: '${room.onlineCount} kişi',
            badge: Icons.mic,
            onTap: () => context.go('/chat'),
          );
        },
      ),
    );
  }
}

class _FortuneGrid extends StatelessWidget {
  const _FortuneGrid();

  static const List<(String, String)> _items = <(String, String)>[
    ('☕', 'Kahve Falı'),
    ('🃏', 'Tarot Falı'),
    ('🤚', 'El Falı'),
    ('🌙', 'Rüya Tabiri'),
    ('💞', 'Aşk Uyumu'),
    ('🌌', 'Günlük Burç'),
    ('🔢', 'Numeroloji'),
    ('🪽', 'Melek Kartları'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int crossAxisCount = constraints.maxWidth > 720 ? 6 : 4;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 116,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (BuildContext context, int index) {
              final (String icon, String label) = _items[index];
              return NeonIconTile(icon: icon, label: label, size: 88);
            },
          );
        },
      ),
    );
  }
}

class _PopularTellers extends StatelessWidget {
  const _PopularTellers({required this.items});

  final List<FortuneService> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final FortuneService service = items[index];
          return SizedBox(
            width: 108,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CachedNetworkImage(
                            imageUrl: service.advisor.avatarUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              service.isLive ? 'Online' : 'Falcı',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Text('⭐ ${service.rating.toStringAsFixed(1)}'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  service.advisor.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  static const List<(String, String, List<Color>)> _items =
      <(String, String, List<Color>)>[
        ('⚽', 'Canlı Futbol', <Color>[Color(0xFF0BA360), Color(0xFF3CBA92)]),
        ('🎬', 'Dizi & Film', <Color>[Color(0xFFD4145A), Color(0xFFFBB03B)]),
        ('🎮', 'Oyunlar', <Color>[Color(0xFF2E3192), Color(0xFF1BFFFF)]),
        ('🔥', 'Trendler', <Color>[Color(0xFFFF512F), Color(0xFFDD2476)]),
        ('⭐', 'Ünlüler', <Color>[Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
        ('💜', 'Fan Club', <Color>[Color(0xFFDA22FF), Color(0xFF9733EE)]),
        ('👥', 'Davet Et', <Color>[Color(0xFF2193B0), Color(0xFF6DD5ED)]),
        ('🎁', 'Hediyeler', <Color>[Color(0xFFFC466B), Color(0xFF3F5EFB)]),
      ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 112,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (BuildContext context, int index) {
          final (String icon, String label, List<Color> colors) = _items[index];
          return NeonIconTile(
            icon: icon,
            label: label,
            size: 82,
            gradient: LinearGradient(colors: colors),
          );
        },
      ),
    );
  }
}

class _GoldPlans extends StatelessWidget {
  const _GoldPlans({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const List<(String, String, String)> plans = <(String, String, String)>[
      ('👑', 'Basic', '100 TL'),
      ('💎', 'Premium', '250 TL'),
      ('🌟', 'Gold', '500 TL'),
      ('🔮', 'Diamond', '1000 TL'),
    ];
    return SizedBox(
      height: 126,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final (String icon, String name, String price) = plans[index];
          return SizedBox(
            width: 104,
            child: GlassCard(
              padding: const EdgeInsets.all(10),
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(name, style: const TextStyle(color: Colors.amber)),
                ],
              ),
            ),
          );
        },
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
