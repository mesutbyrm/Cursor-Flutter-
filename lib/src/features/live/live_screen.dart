import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_models.dart';
import '../../core/app_state.dart';
import '../../shared/ui.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  final PageController _controller = PageController();
  final TextEditingController _comment = TextEditingController();
  final List<LiveStream> _localStreams = <LiveStream>[];
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveStreamsProvider);
    return live.when(
      loading: () => const LoadingState(label: 'Canlı yayınlar yükleniyor'),
      error: (error, _) => _LivePager(
        streams: _localStreams,
        onCreate: _createLive,
        controller: _controller,
      ),
      data: (items) {
        final streams = <LiveStream>[..._localStreams, ...items];
        return _LivePager(
          streams: streams,
          controller: _controller,
          index: _index,
          onChanged: (value) => setState(() => _index = value),
          onCreate: _createLive,
          onGift: (stream) => _showGiftSheet(stream),
          onLike: (stream) => ref.read(apiProvider).likeLive(stream.id),
          commentController: _comment,
          onComment: (stream) async {
            final text = _comment.text.trim();
            if (text.isEmpty) return;
            _comment.clear();
            await ref.read(apiProvider).commentLive(stream.id, text);
          },
        );
      },
    );
  }

  Future<void> _createLive() async {
    final title = TextEditingController(text: 'Yeni canlı yayın');
    final description = TextEditingController(text: 'CanlifalTV canlı sohbet');
    final user = ref.read(sessionProvider).user ?? AppUser.guest;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Yayın aç',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  final stream = await ref
                      .read(apiProvider)
                      .createLiveStream(title.text, description.text);
                  setState(() => _localStreams.insert(0, stream));
                } catch (_) {
                  setState(
                    () => _localStreams.insert(
                      0,
                      LiveStream(
                        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
                        title: title.text,
                        description: description.text,
                        host: user,
                        viewerCount: 1,
                        likeCount: 0,
                        commentCount: 0,
                        roomId: 'local-room',
                        status: 'live',
                      ),
                    ),
                  );
                }
                navigator.pop();
              },
              icon: const Icon(Icons.videocam),
              label: const Text('Başlat'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftSheet(LiveStream stream) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final gifts = ref.watch(giftsProvider);
        return gifts.when(
          data: (items) => GridView.count(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            crossAxisCount: 3,
            children: items
                .map(
                  (gift) => InkWell(
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref
                          .read(apiProvider)
                          .sendLiveGift(stream.id, gift.id);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(gift.icon, style: const TextStyle(fontSize: 28)),
                        Text(gift.name, maxLines: 1),
                        Text('${gift.price} coin'),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          error: (error, _) =>
              ErrorState(message: 'Hediyeler alınamadı: $error'),
          loading: () => const LoadingState(label: 'Hediyeler yükleniyor'),
        );
      },
    );
  }
}

class _LivePager extends StatelessWidget {
  const _LivePager({
    required this.streams,
    required this.onCreate,
    required this.controller,
    this.index = 0,
    this.onChanged,
    this.onGift,
    this.onLike,
    this.commentController,
    this.onComment,
  });

  final List<LiveStream> streams;
  final VoidCallback onCreate;
  final PageController controller;
  final int index;
  final ValueChanged<int>? onChanged;
  final ValueChanged<LiveStream>? onGift;
  final ValueChanged<LiveStream>? onLike;
  final TextEditingController? commentController;
  final ValueChanged<LiveStream>? onComment;

  @override
  Widget build(BuildContext context) {
    if (streams.isEmpty) {
      return Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.live_tv, size: 52),
              const SizedBox(height: 12),
              const Text(
                'Aktif yayın yok',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.videocam),
                label: const Text('Yayın aç'),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: <Widget>[
        PageView.builder(
          controller: controller,
          scrollDirection: Axis.vertical,
          onPageChanged: onChanged,
          itemCount: streams.length,
          itemBuilder: (context, i) => _LivePage(stream: streams[i]),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.videocam),
            label: const Text('Yayın aç'),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 130,
          child: _ActionRail(
            stream: streams[index],
            onGift: onGift,
            onLike: onLike,
          ),
        ),
        Positioned(
          left: 16,
          right: 82,
          bottom: 24,
          child: _LiveBottom(
            stream: streams[index],
            controller: commentController,
            onComment: onComment,
          ),
        ),
      ],
    );
  }
}

class _LivePage extends StatelessWidget {
  const _LivePage({required this.stream});

  final LiveStream stream;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.1,
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF111827), Colors.black],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sensors,
          size: 160,
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({required this.stream, this.onGift, this.onLike});

  final LiveStream stream;
  final ValueChanged<LiveStream>? onGift;
  final ValueChanged<LiveStream>? onLike;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppAvatar(
          imageUrl: stream.host.image,
          fallback: stream.host.name,
          radius: 25,
        ),
        const SizedBox(height: 16),
        _round(
          Icons.favorite,
          compactCount(stream.likeCount),
          () => onLike?.call(stream),
        ),
        _round(Icons.mode_comment, compactCount(stream.commentCount), () {}),
        _round(Icons.card_giftcard, 'Hediye', () => onGift?.call(stream)),
        _round(Icons.share, 'Paylaş', () {}),
      ],
    );
  }

  Widget _round(IconData icon, String text, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: <Widget>[
        IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _LiveBottom extends StatelessWidget {
  const _LiveBottom({required this.stream, this.controller, this.onComment});

  final LiveStream stream;
  final TextEditingController? controller;
  final ValueChanged<LiveStream>? onComment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Chip(
          label: Text('CANLI • ${compactCount(stream.viewerCount)} izleyici'),
          backgroundColor: Colors.red,
        ),
        Text(
          stream.title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        Text('@${stream.host.username} • ${stream.description}'),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Yorum yaz...'),
              ),
            ),
            IconButton.filled(
              onPressed: () => onComment?.call(stream),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}
