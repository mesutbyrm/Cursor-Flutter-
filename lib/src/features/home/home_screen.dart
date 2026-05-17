import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_models.dart';
import '../../shared/ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final live = ref.watch(liveStreamsProvider);
    final trends = ref.watch(trendsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedProvider);
        ref.invalidate(liveStreamsProvider);
        ref.invalidate(trendsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: <Widget>[
          _Hero(),
          const SizedBox(height: 20),
          const _Stories(),
          const SizedBox(height: 20),
          SectionHeader(title: 'Öne çıkan canlı yayınlar', action: 'Tümü'),
          live.when(
            data: (items) => _LiveStrip(streams: items),
            error: (error, _) =>
                ErrorState(message: 'Canlı yayınlar alınamadı: $error'),
            loading: () =>
                const LoadingState(label: 'Canlı yayınlar yükleniyor'),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Trend içerikler'),
          trends.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .take(8)
                  .map((item) => Chip(label: Text(item.title)))
                  .toList(),
            ),
            error: (_, _) => const Wrap(
              spacing: 8,
              children: <Widget>[
                Chip(label: Text('#canlifal')),
                Chip(label: Text('#canliyayin')),
                Chip(label: Text('#kahvefali')),
              ],
            ),
            loading: () => const LoadingState(label: 'Trendler yükleniyor'),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Son paylaşımlar'),
          feed.when(
            data: (posts) => Column(
              children: posts.map((post) => _PostCard(post: post)).toList(),
            ),
            error: (error, _) => ErrorState(message: 'Akış alınamadı: $error'),
            loading: () => const LoadingState(label: 'Akış yükleniyor'),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: premiumGradient(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Premium canlı sosyal fal deneyimi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Canlı yayın, sesli odalar, FanClub, hediyeler ve sosyal akış tek uygulamada.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              _HeroPill(Icons.live_tv, 'Canlı'),
              _HeroPill(Icons.graphic_eq, 'Sesli oda'),
              _HeroPill(Icons.card_giftcard, 'Hediye'),
              _HeroPill(Icons.workspace_premium, 'Premium'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(text),
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    );
  }
}

class _Stories extends StatelessWidget {
  const _Stories();

  @override
  Widget build(BuildContext context) {
    const names = <String>['Sen', 'Aylin', 'Tarot', 'Astro', 'FanClub', 'Gold'];
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[AppTheme.primary, AppTheme.secondary],
                ),
              ),
              child: CircleAvatar(
                radius: 29,
                child: Text(names[index].characters.first),
              ),
            ),
            const SizedBox(height: 6),
            Text(names[index], style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _LiveStrip extends StatelessWidget {
  const _LiveStrip({required this.streams});

  final List<LiveStream> streams;

  @override
  Widget build(BuildContext context) {
    if (streams.isEmpty) {
      return const GlassCard(
        child: Text('Şu anda aktif canlı yayın bulunamadı.'),
      );
    }
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: streams.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final stream = streams[index];
          return SizedBox(
            width: 150,
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topRight,
                    child: Icon(Icons.circle, color: Colors.red, size: 12),
                  ),
                  const Spacer(),
                  Text(
                    stream.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text('@${stream.host.username}', maxLines: 1),
                  Text('${compactCount(stream.viewerCount)} izleyici'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppAvatar(
                  imageUrl: post.author.image,
                  fallback: post.author.name,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.author.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.content),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(compactCount(post.likeCount)),
                const SizedBox(width: 18),
                const Icon(Icons.mode_comment_outlined),
                const SizedBox(width: 4),
                Text(compactCount(post.commentCount)),
                const Spacer(),
                const Icon(Icons.bookmark_border),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
