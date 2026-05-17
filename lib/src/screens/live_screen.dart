import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../widgets.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LiveStream>> streams = ref.watch(liveStreamsProvider);
    return ResponsiveMaxWidth(
      child: streams.when(
        data: (List<LiveStream> items) => CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _LiveHero(onCreate: () => context.go('/live/create')),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Canlı yayınlar',
                subtitle: 'Yayını aç, izle, sohbete katıl ve hediye gönder',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverGrid.builder(
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: MediaQuery.sizeOf(context).width > 720
                      ? 380
                      : 520,
                  mainAxisExtent: 360,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _LiveRoomCard(stream: items[index]);
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('Canlı yayınlar yüklenemedi: $error')),
      ),
    );
  }
}

class LiveWatchScreen extends ConsumerWidget {
  const LiveWatchScreen({required this.streamId, super.key});

  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CanlifalRepository>(
      future: ref.watch(canlifalRepositoryProvider.future),
      builder:
          (BuildContext context, AsyncSnapshot<CanlifalRepository> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return FutureBuilder<LiveStream?>(
              future: snapshot.data!.getLiveStream(streamId),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<LiveStream?> streamSnapshot,
                  ) {
                    final LiveStream? stream = streamSnapshot.data;
                    if (streamSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (stream == null) {
                      return const _LiveUnavailable(
                        title: 'Yayın bulunamadı',
                        message:
                            'Bu canlı yayın kapanmış veya yayın listesinde yok.',
                      );
                    }
                    return _LiveWatchBody(stream: stream);
                  },
            );
          },
    );
  }
}

class LiveBroadcastSetupScreen extends ConsumerStatefulWidget {
  const LiveBroadcastSetupScreen({super.key});

  @override
  ConsumerState<LiveBroadcastSetupScreen> createState() =>
      _LiveBroadcastSetupScreenState();
}

class _LiveBroadcastSetupScreenState
    extends ConsumerState<LiveBroadcastSetupScreen> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Canlifal Canlı Yayını',
  );
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Fal, tarot ve canlı sohbet yayını.',
  );
  bool _isStarting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveMaxWidth(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        children: <Widget>[
          GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Canlı yayın aç',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yayın başlatma akışı API tarafında LiveKit/Tencent oda tokeni üretildiğinde doğrudan yayın odasına bağlanır.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Yayın başlığı',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const <Widget>[
                    StatPill(icon: Icons.mic, label: 'ses', value: 'aktif'),
                    StatPill(
                      icon: Icons.videocam,
                      label: 'kamera',
                      value: 'HD',
                    ),
                    StatPill(icon: Icons.shield, label: 'mod', value: 'hazır'),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isStarting ? null : _startBroadcast,
                  icon: _isStarting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sensors),
                  label: const Text('Yayını başlat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBroadcast() async {
    setState(() => _isStarting = true);
    final CanlifalRepository repository = await ref.read(
      canlifalRepositoryProvider.future,
    );
    final Map<String, dynamic> response = await repository.createLiveRoom(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isStarting = false);
    final String? streamId = response['id'] as String?;
    if (streamId != null && streamId.isNotEmpty) {
      context.go('/live/$streamId');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yayın altyapısı bekleniyor'),
          content: Text(
            response['message'] as String? ??
                'Canlı yayın açmak için backend tarafında oda ve yayın tokeni dönülmelidir.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}

class _LiveHero extends StatelessWidget {
  const _LiveHero({required this.onCreate});

  final VoidCallback onCreate;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.redAccent.withValues(alpha: .18),
                  ),
                  child: const Text(
                    'CANLI',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Yayın açma ve izleme artık ayrı akışta.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yayın kartına dokun, izleme ekranına geç, sohbet ve hediye panelini aynı yerde kullan.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Yayın Aç'),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomCard extends StatelessWidget {
  const _LiveRoomCard({required this.stream});

  final LiveStream stream;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go('/live/${stream.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: stream.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: .12),
                        Colors.black.withValues(alpha: .78),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: _LiveBadge(status: stream.status),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: StatPill(
                    icon: Icons.visibility,
                    label: 'izleyici',
                    value: compactNumber(stream.viewers),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: <Widget>[
                      GradientAvatar(
                        imageUrl: stream.host.avatarUrl,
                        radius: 22,
                        isLive: stream.status == StreamStatus.live,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              stream.host.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '@${stream.host.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                Text(
                  stream.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stream.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final String tag in stream.tags.take(2))
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(tag),
                            ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/live/${stream.id}'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('İzle'),
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

class _LiveWatchBody extends ConsumerWidget {
  const _LiveWatchBody({required this.stream});

  final LiveStream stream;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _AdaptiveLivePlayer(stream: stream),
        Positioned(
          left: 12,
          top: 10,
          child: SafeArea(
            child: IconButton.filledTonal(
              onPressed: () => context.go('/live'),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          top: 74,
          child: SafeArea(
            child: Row(
              children: <Widget>[
                GradientAvatar(
                  imageUrl: stream.host.avatarUrl,
                  radius: 24,
                  isLive: stream.status == StreamStatus.live,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        stream.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${stream.host.displayName} · ${compactNumber(stream.viewers)} izleyici',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(authControllerProvider).follow(stream.host),
                  child: const Text('Takip'),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 172,
          child: _LiveActionRail(stream: stream),
        ),
        Positioned(
          left: 18,
          right: 92,
          bottom: 174,
          child: _CommentRail(host: stream.host),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 20,
          child: SafeArea(child: _LiveInputPanel(stream: stream)),
        ),
      ],
    );
  }
}

class _AdaptiveLivePlayer extends StatefulWidget {
  const _AdaptiveLivePlayer({required this.stream});

  final LiveStream stream;

  @override
  State<_AdaptiveLivePlayer> createState() => _AdaptiveLivePlayerState();
}

class _AdaptiveLivePlayerState extends State<_AdaptiveLivePlayer> {
  VideoPlayerController? _videoController;
  WebViewController? _webViewController;
  bool _isPreparing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? video = _videoController;
    final WebViewController? webView = _webViewController;

    if (_error != null) {
      return _LiveUnavailable(title: 'Yayın açılmadı', message: _error!);
    }

    if (video != null && video.value.isInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
        ),
      );
    }

    if (webView != null) {
      return WebViewWidget(controller: webView);
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CachedNetworkImage(
          imageUrl: widget.stream.thumbnailUrl,
          fit: BoxFit.cover,
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .62)),
        ),
        if (_isPreparing) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Future<void> _prepare() async {
    if (widget.stream.hasNativePlayback) {
      await _prepareNativePlayer();
      return;
    }
    _prepareWebFallback();
  }

  Future<void> _prepareNativePlayer() async {
    try {
      final VideoPlayerController controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.stream.playbackUrl!),
      );
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _isPreparing = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Video stream başlatılamadı: $error';
        _isPreparing = false;
      });
    }
  }

  void _prepareWebFallback() {
    final Uri? uri = Uri.tryParse(widget.stream.watchUrl);
    if (uri == null) {
      setState(() {
        _error = 'Yayın adresi geçersiz.';
        _isPreparing = false;
      });
      return;
    }

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isPreparing = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted || error.isForMainFrame == false) {
              return;
            }
            setState(() {
              _error =
                  'Canlifal canlı yayın sayfası yüklenemedi: '
                  '${error.description}';
              _isPreparing = false;
            });
          },
        ),
      )
      ..loadRequest(uri);

    setState(() {
      _webViewController = controller;
    });
  }
}

class _LiveInputPanel extends ConsumerWidget {
  const _LiveInputPanel({required this.stream});

  final LiveStream stream;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? viewer = ref.watch(authControllerProvider).user;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '${viewer?.displayName ?? 'Kullanıcı'} olarak yaz',
                isDense: true,
                suffixIcon: const Icon(Icons.send),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _GiftDock(
            onGift: (GiftItem gift) {
              final bool ok = ref
                  .read(authControllerProvider)
                  .spendCoins(gift.priceCoins);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? '${gift.name} hediyesi gönderildi.'
                        : 'Coin bakiyesi yetersiz.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LiveActionRail extends StatelessWidget {
  const _LiveActionRail({required this.stream});

  final LiveStream stream;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _LiveAction(icon: Icons.favorite, label: 'Beğen'),
        _LiveAction(icon: Icons.chat_bubble, label: 'Yorum'),
        if (stream.isMultiGuest)
          _LiveAction(icon: Icons.group_add, label: 'Katıl'),
        _LiveAction(icon: Icons.shield, label: 'Mod'),
        _LiveAction(icon: Icons.report_gmailerrorred, label: 'Şikayet'),
      ],
    );
  }
}

class _CommentRail extends StatelessWidget {
  const _CommentRail({required this.host});

  final AppUser host;

  @override
  Widget build(BuildContext context) {
    final List<String> comments = <String>[
      '${host.displayName}: Yayına hoş geldiniz.',
      'mod_aylin: Lütfen saygılı yorum yapalım.',
      'can_user: 👑 hediyesi gönderdi!',
      'astrofan: Ben de canlı danışman sırası aldım.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String comment in comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: .46),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(comment),
              ),
            ),
          ),
      ],
    );
  }
}

class _GiftDock extends StatelessWidget {
  const _GiftDock({required this.onGift});

  final ValueChanged<GiftItem> onGift;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GiftItem>(
      tooltip: 'Hediye gönder',
      onSelected: onGift,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<GiftItem>>[
          for (final GiftItem gift in CanlifalSeed.gifts)
            PopupMenuItem<GiftItem>(
              value: gift,
              child: Text(
                '${gift.emoji} ${gift.name} · ${gift.priceCoins} coin',
              ),
            ),
        ];
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFFF2D75), Color(0xFF8B5CF6)],
          ),
        ),
        child: const Icon(Icons.card_giftcard),
      ),
    );
  }
}

class _LiveAction extends StatelessWidget {
  const _LiveAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: .46),
            child: Icon(icon),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.status});

  final StreamStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isLive = status == StreamStatus.live;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isLive ? Colors.redAccent : Colors.amber,
      ),
      child: Text(
        isLive ? 'CANLI' : 'PLANLI',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _LiveUnavailable extends StatelessWidget {
  const _LiveUnavailable({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ResponsiveMaxWidth(
      maxWidth: 640,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.live_tv, size: 54, color: Color(0xFFFF2D75)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/live'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Canlılara dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
