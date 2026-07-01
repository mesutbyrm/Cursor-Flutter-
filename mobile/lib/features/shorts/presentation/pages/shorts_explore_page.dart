import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/short_explore_entity.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';

/// Keşfet — trend videolar, hashtag'ler ve popüler müzikler.
class ShortsExplorePage extends ConsumerStatefulWidget {
  const ShortsExplorePage({super.key});

  @override
  ConsumerState<ShortsExplorePage> createState() => _ShortsExplorePageState();
}

class _ShortsExplorePageState extends ConsumerState<ShortsExplorePage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(shortsExploreProvider.notifier).search(_searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final explore = ref.watch(shortsExploreProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Keşfet'),
        actions: [
          IconButton(
            onPressed: () => context.push('/shorts'),
            icon: const Icon(Icons.play_circle_outline_rounded),
            tooltip: 'Akış',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Video, hashtag veya müzik ara...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: explore.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.accentPurple),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$e', style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(shortsExploreProvider.notifier).refresh(),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(shortsExploreProvider.notifier).refresh(),
                child: _ExploreBody(page: page),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreBody extends ConsumerWidget {
  const _ExploreBody({required this.page});

  final ShortExplorePage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          ref.read(shortsExploreProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (page.trendingHashtags.isNotEmpty) ...[
            const _SectionTitle('Trend Hashtag\'ler'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in page.trendingHashtags)
                  _HashtagChip(hashtag: tag),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (page.popularMusic.isNotEmpty) ...[
            const _SectionTitle('Popüler Müzikler'),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: page.popularMusic.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) =>
                    _MusicTile(music: page.popularMusic[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const _SectionTitle('Trend Videolar'),
          const SizedBox(height: 8),
          if (page.videos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Henüz trend video yok',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 9 / 14,
              ),
              itemCount: page.videos.length,
              itemBuilder: (context, i) =>
                  _VideoTile(video: page.videos[i]),
            ),
        ],
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
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  const _HashtagChip({required this.hashtag});

  final ShortHashtagEntity hashtag;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('#${hashtag.name}'),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () => context.push('/shorts'),
    );
  }
}

class _MusicTile extends StatelessWidget {
  const _MusicTile({required this.music});

  final ShortMusicEntity music;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: music.coverUrl != null && music.coverUrl!.isNotEmpty
                ? CanlifalNetworkImage(
                    url: music.coverUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.white12,
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  music.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (music.artist != null)
                  Text(
                    music.artist!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final ShortVideoEntity video;

  @override
  Widget build(BuildContext context) {
    final thumb = video.thumbnailUrl;
    return GestureDetector(
      onTap: () => context.push('/shorts?videoId=${video.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb != null && thumb.isNotEmpty)
              CanlifalNetworkImage(url: thumb, fit: BoxFit.cover)
            else
              const ColoredBox(
                color: Color(0xFF1A0F3D),
                child: Center(
                  child: Icon(Icons.play_circle_outline, color: Colors.white54),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                video.description?.trim().isNotEmpty == true
                    ? video.description!.trim()
                    : '@${video.author?.username ?? 'video'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
