import 'package:flutter/material.dart';

const String kAppName = 'VivaLive';
const String kLogoAsset = 'assets/brand/vivalive_logo.png';

void main() {
  runApp(const VivaLiveApp());
}

class VivaLiveApp extends StatefulWidget {
  const VivaLiveApp({super.key});

  @override
  State<VivaLiveApp> createState() => _VivaLiveAppState();
}

class _VivaLiveAppState extends State<VivaLiveApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F3FF),
        useMaterial3: true,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _showSplash ? const SplashScreen() : const SocialShell(),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF13052E),
              Color(0xFF4C1D95),
              Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const _LogoMark(size: 118, showGlow: true),
              const SizedBox(height: 22),
              const Text(
                kAppName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Canlı yayın • Sesli oda • Sosyal akış',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 42),
              SizedBox(
                width: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    color: Colors.white,
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

class SocialShell extends StatefulWidget {
  const SocialShell({super.key});

  @override
  State<SocialShell> createState() => _SocialShellState();
}

class _SocialShellState extends State<SocialShell> {
  static const List<_Destination> _destinations = <_Destination>[
    _Destination('Akış', Icons.dynamic_feed_outlined, Icons.dynamic_feed),
    _Destination('Keşfet', Icons.travel_explore_outlined, Icons.travel_explore),
    _Destination('Canlı', Icons.live_tv_outlined, Icons.live_tv),
    _Destination('Odalar', Icons.graphic_eq_outlined, Icons.graphic_eq),
    _Destination('Profil', Icons.person_outline, Icons.person),
  ];

  int _currentIndex = 0;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final _Destination current = _destinations[_currentIndex];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            const _LogoMark(size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  kAppName,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  current.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          _NotificationButton(count: 9, onTap: _showApiNotice),
          IconButton(
            tooltip: 'Mesajlar',
            onPressed: _showApiNotice,
            icon: const Icon(Icons.mark_chat_unread_outlined),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2 || _currentIndex == 3
          ? FloatingActionButton.extended(
              onPressed: _showApiNotice,
              icon: Icon(_currentIndex == 2 ? Icons.videocam : Icons.mic),
              label: Text(_currentIndex == 2 ? 'Yayın aç' : 'Oda aç'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (_isRefreshing) const LinearProgressIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _PageBody(
                    key: ValueKey<int>(_currentIndex),
                    index: _currentIndex,
                    onAction: _showApiNotice,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 72,
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() => _currentIndex = index);
            },
            destinations: <Widget>[
              for (final _Destination destination in _destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API verileri için ekran yenilendi')),
    );
  }

  void _showApiNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu alan API bilgileri gelince canlı veriye bağlanacak.'),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({super.key, required this.index, required this.onAction});

  final int index;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
      children: <Widget>[
        if (index == 0) FeedPage(onAction: onAction),
        if (index == 1) ExplorePage(onAction: onAction),
        if (index == 2) LivePage(onAction: onAction),
        if (index == 3) RoomsPage(onAction: onAction),
        if (index == 4) ProfilePage(onAction: onAction),
      ],
    );
  }
}

class FeedPage extends StatelessWidget {
  const FeedPage({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HomeHero(onAction: onAction),
        const SizedBox(height: 18),
        const _StoryRail(),
        const SizedBox(height: 18),
        const _SectionTitle('Sosyal akış'),
        const SizedBox(height: 10),
        _FeedPost(
          avatarColor: const Color(0xFF7C3AED),
          name: 'Mina Live',
          username: '@mina',
          text:
              'Yeni canlı yayın odamız başladı. Hediye efekti, sesli sohbet ve özel FunClub odası açık!',
          likes: '12.4K',
          comments: '842',
          onAction: onAction,
        ),
        const SizedBox(height: 12),
        _FeedPost(
          avatarColor: const Color(0xFF06B6D4),
          name: 'Ege',
          username: '@egeplus',
          text:
              'Bugünün trendi: kısa video, ortak yayın, jeton görevleri ve arkadaş daveti.',
          likes: '8.1K',
          comments: '391',
          onAction: onAction,
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Hızlı sistemler'),
        const SizedBox(height: 10),
        _QuickGrid(onAction: onAction),
      ],
    );
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SearchPanel(),
        const SizedBox(height: 16),
        const _SectionTitle('Trendler'),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _TrendChip('#canliyayinda'),
            _TrendChip('#seslioda'),
            _TrendChip('#hediyeyagmuru'),
            _TrendChip('#funclub'),
            _TrendChip('#goldhaftasi'),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('12 yorum türü'),
        const SizedBox(height: 10),
        _FortuneTypesGrid(onAction: onAction),
        const SizedBox(height: 18),
        const _SectionTitle('Oyunlar ve görevler'),
        const SizedBox(height: 10),
        _GameCarousel(onAction: onAction),
      ],
    );
  }
}

class LivePage extends StatelessWidget {
  const LivePage({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LiveStage(onAction: onAction),
        const SizedBox(height: 16),
        const _SectionTitle('Canlı yayınlar'),
        const SizedBox(height: 10),
        _LiveListTile(
          title: 'Gece sohbeti',
          host: 'Lara',
          viewers: '21.8K',
          color: const Color(0xFFEC4899),
          onAction: onAction,
        ),
        const SizedBox(height: 10),
        _LiveListTile(
          title: 'Ortak yayın',
          host: 'Deniz & Arda',
          viewers: '9.4K',
          color: const Color(0xFF7C3AED),
          onAction: onAction,
        ),
        const SizedBox(height: 16),
        _GiftPanel(onAction: onAction),
      ],
    );
  }
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _RoomHeader(onAction: onAction),
        const SizedBox(height: 16),
        const _SectionTitle('Sesli sohbet odaları'),
        const SizedBox(height: 10),
        _AudioRoomCard(
          title: 'Muhabbet Cafe',
          subtitle: '12 konuşmacı • 248 dinleyici',
          color: const Color(0xFF7C3AED),
          onAction: onAction,
        ),
        const SizedBox(height: 12),
        _AudioRoomCard(
          title: 'Oyun gecesi',
          subtitle: '6 konuşmacı • 183 dinleyici',
          color: const Color(0xFF10B981),
          onAction: onAction,
        ),
        const SizedBox(height: 12),
        _AudioRoomCard(
          title: 'Gold üyeler kulübü',
          subtitle: 'Özel oda • 74 dinleyici',
          color: const Color(0xFFF59E0B),
          onAction: onAction,
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ProfileHeader(onAction: onAction),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _WalletCard(
                title: 'Jeton',
                amount: '12.850',
                icon: Icons.monetization_on,
                color: const Color(0xFFF59E0B),
                onAction: onAction,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WalletCard(
                title: 'Gold',
                amount: 'Aktif',
                icon: Icons.workspace_premium,
                color: const Color(0xFF7C3AED),
                onAction: onAction,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MenuCard(
          items: <_MenuItem>[
            _MenuItem(Icons.card_giftcard, 'Hediye geçmişi'),
            _MenuItem(Icons.group_add, 'Davet sistemi'),
            _MenuItem(Icons.notifications_active, 'Anlık bildirimler'),
            _MenuItem(Icons.favorite, 'FunClub üyelikleri'),
            _MenuItem(Icons.settings, 'Ayarlar'),
          ],
          onAction: onAction,
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF6D28D9),
        Color(0xFFEC4899),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _LogoMark(size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Canlı sosyal platform',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'TikTok enerjisi, Instagram profili, Facebook akışı.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              _LightPill(Icons.videocam, 'Canlı yayın'),
              _LightPill(Icons.graphic_eq, 'Sesli oda'),
              _LightPill(Icons.card_giftcard, 'Animasyonlu hediye'),
              _LightPill(Icons.bolt, 'Anlık bildirim'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6D28D9),
                  ),
                  onPressed: onAction,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Keşfet'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Paylaş'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryRail extends StatelessWidget {
  const _StoryRail();

  static const List<_Story> _stories = <_Story>[
    _Story('Sen', Icons.add, Color(0xFF7C3AED)),
    _Story('Lara', Icons.videocam, Color(0xFFEC4899)),
    _Story('Ege', Icons.sports_esports, Color(0xFF10B981)),
    _Story('Mina', Icons.star, Color(0xFFF59E0B)),
    _Story('Club', Icons.favorite, Color(0xFF06B6D4)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final _Story story = _stories[index];
          return Column(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[story.color, const Color(0xFF7C3AED)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(story.icon, color: story.color),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(story.label, style: Theme.of(context).textTheme.labelMedium),
            ],
          );
        },
      ),
    );
  }
}

class _FeedPost extends StatelessWidget {
  const _FeedPost({
    required this.avatarColor,
    required this.name,
    required this.username,
    required this.text,
    required this.likes,
    required this.comments,
    required this.onAction,
  });

  final Color avatarColor;
  final String name;
  final String username;
  final String text;
  final String likes;
  final String comments;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: avatarColor.withValues(alpha: 0.14),
                foregroundColor: avatarColor,
                child: Text(name.characters.first),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      username,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAction,
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  avatarColor.withValues(alpha: 0.92),
                  const Color(0xFF111827),
                ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 58,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _DarkBadge(
                    icon: Icons.local_fire_department,
                    text: 'Trend',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _ActionCounter(Icons.favorite, likes, onAction),
              _ActionCounter(Icons.mode_comment, comments, onAction),
              _ActionCounter(Icons.card_giftcard, 'Hediye', onAction),
              const Spacer(),
              IconButton(onPressed: onAction, icon: const Icon(Icons.share)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.onAction});

  final VoidCallback onAction;

  static const List<_Feature> _features = <_Feature>[
    _Feature(Icons.workspace_premium, 'Gold üyelik', 'Özel oda ve rozet'),
    _Feature(Icons.monetization_on, 'Jeton satın al', 'Hediye göndermek için'),
    _Feature(Icons.favorite, 'FunClub', 'İçerik üreticini destekle'),
    _Feature(Icons.person_add_alt_1, 'Davet et', 'Arkadaş getir, ödül kazan'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _Feature feature = _features[index];
        return _SurfaceCard(
          onTap: onAction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(feature.icon, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(
                feature.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                feature.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Yayın, oda, kişi, trend veya oyun ara',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Icon(Icons.tune),
        ],
      ),
    );
  }
}

class _FortuneTypesGrid extends StatelessWidget {
  const _FortuneTypesGrid({required this.onAction});

  final VoidCallback onAction;

  static const List<String> _types = <String>[
    'Kahve',
    'Tarot',
    'Astroloji',
    'Rüya',
    'Numeroloji',
    'El falı',
    'Aşk',
    'Kariyer',
    'Enerji',
    'Günlük',
    'Katina',
    'Su falı',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (BuildContext context, int index) {
        return _SurfaceCard(
          onTap: onAction,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                _types[index],
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameCarousel extends StatelessWidget {
  const _GameCarousel({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _GameCard(
            title: 'Çarkı çevir',
            icon: Icons.casino,
            color: const Color(0xFF7C3AED),
            onAction: onAction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GameCard(
            title: 'Günlük görev',
            icon: Icons.emoji_events,
            color: const Color(0xFFF59E0B),
            onAction: onAction,
          ),
        ),
      ],
    );
  }
}

class _LiveStage extends StatelessWidget {
  const _LiveStage({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF111827),
        Color(0xFF7C3AED),
      ]),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: GridView.count(
                crossAxisCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: List<Widget>.generate(
                  24,
                  (int index) => const Icon(Icons.star, color: Colors.white24),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _DarkBadge(icon: Icons.circle, text: 'CANLI 18.2K'),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _DarkBadge(icon: Icons.monetization_on, text: 'Jeton'),
          ),
          const Center(
            child: Icon(Icons.person, color: Colors.white, size: 96),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Yayın başlığı buraya gelecek',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'API’den yayın sahibi, izleyici, sohbet ve hediye akışı çekilecek.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text('Hediye gönder'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: onAction,
                      icon: const Icon(Icons.chat_bubble),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: onAction,
                      icon: const Icon(Icons.favorite),
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

class _LiveListTile extends StatelessWidget {
  const _LiveListTile({
    required this.title,
    required this.host,
    required this.viewers,
    required this.color,
    required this.onAction,
  });

  final String title;
  final String host;
  final String viewers;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Row(
        children: <Widget>[
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.live_tv, color: color, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text('Yayıncı: $host'),
                const SizedBox(height: 8),
                _MetaPill(icon: Icons.visibility, text: viewers),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _GiftPanel extends StatelessWidget {
  const _GiftPanel({required this.onAction});

  final VoidCallback onAction;

  static const List<_Gift> _gifts = <_Gift>[
    _Gift('Kalp', '10', Icons.favorite, Color(0xFFEC4899)),
    _Gift('Roket', '250', Icons.rocket_launch, Color(0xFF7C3AED)),
    _Gift('Taç', '500', Icons.workspace_premium, Color(0xFFF59E0B)),
  ];

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Sesli ve görsel hediyeler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final _Gift gift in _gifts) ...<Widget>[
                Expanded(
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gift.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: <Widget>[
                          Icon(gift.icon, color: gift.color),
                          const SizedBox(height: 6),
                          Text(
                            gift.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text('${gift.price} jeton'),
                        ],
                      ),
                    ),
                  ),
                ),
                if (gift != _gifts.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF0F766E),
        Color(0xFF06B6D4),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.graphic_eq, color: Colors.white, size: 42),
          const SizedBox(height: 16),
          const Text(
            'Sesli odalarda konuş, dinle, hediye gönder.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.mic),
            label: const Text('Oda oluştur'),
          ),
        ],
      ),
    );
  }
}

class _AudioRoomCard extends StatelessWidget {
  const _AudioRoomCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.graphic_eq, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MetaPill(icon: Icons.card_giftcard, text: 'Hediye açık'),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle),
          const SizedBox(height: 14),
          Row(
            children: List<Widget>.generate(
              5,
              (int index) => Padding(
                padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12 + index * 0.04),
                  child: Icon(Icons.person, color: color, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF111827),
        Color(0xFF7C3AED),
      ]),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 46, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Kullanıcı Adı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '@kullanici • Gold üye',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _LightPill(Icons.verified, 'Doğrulanmış profil'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const <Widget>[
              _ProfileStat('12.8K', 'Takipçi'),
              _ProfileStat('842', 'Takip'),
              _ProfileStat('1.4M', 'Beğeni'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Hikaye ekle'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: onAction,
                  icon: const Icon(Icons.edit),
                  label: const Text('Profili düzenle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.onAction,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title),
          Text(
            amount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, required this.onAction});

  final List<_MenuItem> items;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int index = 0; index < items.length; index++) ...<Widget>[
            ListTile(
              leading: Icon(
                items[index].icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(items[index].title),
              trailing: const Icon(Icons.chevron_right),
              onTap: onAction,
            ),
            if (index != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const Text('Jeton ve rozet ödülleri'),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IconButton(
          tooltip: 'Bildirimler',
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size, this.showGlow = false});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        kLogoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (!showGlow) {
      return image;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.28),
            blurRadius: 34,
            spreadRadius: 4,
          ),
        ],
      ),
      child: image,
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.46),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.local_fire_department, size: 18),
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _LightPill extends StatelessWidget {
  const _LightPill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _DarkBadge extends StatelessWidget {
  const _DarkBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCounter extends StatelessWidget {
  const _ActionCounter(this.icon, this.text, this.onTap);

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

BoxDecoration _gradientDecoration(List<Color> colors) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: colors.first.withValues(alpha: 0.24),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _Story {
  const _Story(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _Feature {
  const _Feature(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

class _Gift {
  const _Gift(this.name, this.price, this.icon, this.color);

  final String name;
  final String price;
  final IconData icon;
  final Color color;
}

class _MenuItem {
  const _MenuItem(this.icon, this.title);

  final IconData icon;
  final String title;
}
