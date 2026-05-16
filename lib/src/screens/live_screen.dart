import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LiveStream>> streams = ref.watch(liveStreamsProvider);
    return streams.when(
      data: (List<LiveStream> items) => PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          return _LivePage(stream: items[index]);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) =>
          Center(child: Text('$error')),
    );
  }
}

class _LivePage extends ConsumerStatefulWidget {
  const _LivePage({required this.stream});

  final LiveStream stream;

  @override
  ConsumerState<_LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<_LivePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _emojiController;

  @override
  void initState() {
    super.initState();
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? viewer = ref.watch(authControllerProvider).user;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CachedNetworkImage(
          imageUrl: widget.stream.thumbnailUrl,
          fit: BoxFit.cover,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: .15),
                Colors.black.withValues(alpha: .38),
                Colors.black.withValues(alpha: .92),
              ],
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 88,
          top: 16,
          child: Row(
            children: <Widget>[
              GradientAvatar(
                imageUrl: widget.stream.host.avatarUrl,
                radius: 24,
                isLive: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.stream.host.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '@${widget.stream.host.username}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () {},
                child: const Text('Takip et'),
              ),
            ],
          ),
        ),
        Positioned(
          top: 90,
          left: 18,
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              StatPill(
                icon: Icons.remove_red_eye,
                label: 'izleyici',
                value: compactNumber(widget.stream.viewers),
              ),
              if (widget.stream.isMultiGuest)
                const StatPill(icon: Icons.groups, label: 'çoklu', value: '4'),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 126,
          child: Column(
            children: <Widget>[
              _LiveAction(icon: Icons.favorite, label: 'Beğen'),
              _LiveAction(icon: Icons.chat_bubble, label: 'Yorum'),
              _LiveAction(icon: Icons.shield, label: 'Mod'),
              _LiveAction(icon: Icons.report_gmailerrorred, label: 'Şikayet'),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 92,
          bottom: 184,
          child: _CommentRail(host: widget.stream.host),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 24,
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.stream.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              '${viewer?.displayName ?? 'Kullanıcı'} olarak yorum yaz',
                          isDense: true,
                          suffixIcon: const Icon(Icons.send),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GiftDock(
                      onGift: (GiftItem gift) {
                        ref
                            .read(authControllerProvider)
                            .spendCoins(gift.priceCoins);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 88,
          bottom: 260,
          child: AnimatedBuilder(
            animation: _emojiController,
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                opacity: 1 - _emojiController.value,
                child: Transform.translate(
                  offset: Offset(0, -120 * _emojiController.value),
                  child: child,
                ),
              );
            },
            child: const Text('✨', style: TextStyle(fontSize: 42)),
          ),
        ),
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
      '${host.displayName}: Sıradaki fincan çok net görünüyor.',
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
                color: Colors.black.withValues(alpha: .32),
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
            backgroundColor: Colors.black.withValues(alpha: .35),
            child: Icon(icon),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
