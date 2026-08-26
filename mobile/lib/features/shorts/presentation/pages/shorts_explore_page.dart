import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/effects_perf.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_bottom_sheet.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/hero_tags.dart';
import '../../domain/entities/short_explore_entity.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_explore_providers.dart';
import '../providers/shorts_providers.dart';
import '../utils/reverse_geocode_helper.dart';
import '../utils/shorts_count_format.dart';
import 'short_music_feed_page.dart';
import '../widgets/shorts_premium_theme.dart';

/// Keşfet — trend, sana özel, AI, konum, hashtag ve müzik.
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

  Future<void> _pickLocation() async {
    final current = ref.read(shortExploreLocationProvider).valueOrNull;
    final ctrl = TextEditingController(text: current?.label ?? '');
    final picked = await showPremiumBottomSheet<String>(
      context: context,
      child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Konum seç',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Şehir veya bölge',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final service = await Geolocator.isLocationServiceEnabled();
                  if (!service) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Konum servisi kapalı')),
                      );
                    }
                    return;
                  }
                  var perm = await Geolocator.checkPermission();
                  if (perm == LocationPermission.denied) {
                    perm = await Geolocator.requestPermission();
                  }
                  if (perm == LocationPermission.denied ||
                      perm == LocationPermission.deniedForever) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Konum izni gerekli')),
                      );
                    }
                    return;
                  }
                  final pos = await Geolocator.getCurrentPosition();
                  if (!context.mounted) return;
                  final label = await reverseGeocodeLabel(
                    pos.latitude,
                    pos.longitude,
                  );
                  if (context.mounted) {
                    Navigator.pop(
                      context,
                      '__gps__:${pos.latitude},${pos.longitude}:$label',
                    );
                  }
                },
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('GPS konumumu kullan'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final city in ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya'])
                    ActionChip(
                      label: Text(city),
                      onPressed: () => Navigator.pop(context, city),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                child: const Text('Kaydet'),
              ),
              if (current != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, '__clear__'),
                  child: const Text('Konumu kaldır'),
                ),
            ],
          ),
        ),
    );
    if (!mounted || picked == null) return;
    if (picked == '__clear__') {
      await ref.read(shortExploreLocationProvider.notifier).clear();
    } else if (picked.startsWith('__gps__:')) {
      final body = picked.substring('__gps__:'.length);
      final parts = body.split(':');
      final coords = parts.first.split(',');
      if (coords.length == 2) {
        final lat = double.tryParse(coords[0]);
        final lng = double.tryParse(coords[1]);
        final label = parts.length > 1 && parts[1].trim().isNotEmpty
            ? parts.sublist(1).join(':')
            : 'Konumum';
        await ref.read(shortExploreLocationProvider.notifier).setLocation(
              label,
              lat: lat,
              lng: lng,
            );
      }
    } else if (picked.isNotEmpty) {
      await ref.read(shortExploreLocationProvider.notifier).setLocation(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final explore = ref.watch(shortsExploreProvider);
    final location = ref.watch(shortExploreLocationProvider).valueOrNull;

    return Scaffold(
      backgroundColor: ShortsPremiumTheme.chromeBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            child: ProGlassCard(
              tier: GlassTier.static,
              padding: EdgeInsets.zero,
              animateIn: false,
              borderRadius: BorderRadius.circular(14),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Video, hashtag veya müzik ara...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
          ),
          Expanded(
            child: explore.when(
              loading: () => const PremiumShortExploreSkeleton(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ApiException.userMessage(e),
                      style: const TextStyle(color: Colors.white54),
                    ),
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
                child: _ExploreBody(
                  page: page,
                  locationLabel: location?.label ?? page.locationLabel,
                  onPickLocation: _pickLocation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreBody extends ConsumerWidget {
  const _ExploreBody({
    required this.page,
    required this.locationLabel,
    required this.onPickLocation,
  });

  final ShortExplorePage page;
  final String? locationLabel;
  final VoidCallback onPickLocation;

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
        physics: PremiumMotion.listPhysics,
        children: [
          if (page.forYouVideos.isNotEmpty) ...[
            _SectionHeader(
              title: 'Sana Özel',
              subtitle: 'İlgi alanlarına göre öneriler',
              icon: Icons.auto_awesome,
              actionLabel: 'Akışa git',
              onAction: () => context.push('/shorts'),
            ),
            const SizedBox(height: 8),
            _HorizontalVideoStrip(videos: page.forYouVideos),
            const SizedBox(height: 20),
          ],
          if (page.aiRecommendedVideos.isNotEmpty) ...[
            _SectionHeader(
              title: 'Yapay Zekâ Önerileri',
              subtitle: 'AI ile kişiselleştirilmiş seçimler',
              icon: Icons.psychology_alt_outlined,
              badge: 'AI',
            ),
            const SizedBox(height: 8),
            _HorizontalVideoStrip(videos: page.aiRecommendedVideos),
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
            _VideoGrid(videos: page.videos),
          const SizedBox(height: 20),
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
            const _SectionTitle('Trend Müzikler'),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: page.popularMusic.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _MusicTile(music: page.popularMusic[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              const Expanded(
                child: _SectionTitle('Konuma Göre'),
              ),
              TextButton.icon(
                onPressed: onPickLocation,
                icon: const Icon(Icons.place_outlined, size: 18),
                label: Text(locationLabel ?? 'Konum seç'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (page.locationVideos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                locationLabel != null
                    ? '$locationLabel için video bulunamadı'
                    : 'Yakındaki videolar için konum seçin',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            )
          else
            _HorizontalVideoStrip(videos: page.locationVideos),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.accentPink, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.accentPurple.withValues(alpha: 0.35),
                        borderRadius: ShortsPremiumTheme.chipRadius,
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
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

class _HorizontalVideoStrip extends StatelessWidget {
  const _HorizontalVideoStrip({required this.videos});

  final List<ShortVideoEntity> videos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: PremiumMotion.listPhysics,
        itemCount: videos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => SizedBox(
          width: 110,
          child: _VideoTile(video: videos[i], compact: true),
        ),
      ),
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.videos});

  final List<ShortVideoEntity> videos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const spacing = 10.0;
        const aspect = 9 / 14;
        final gridHeight = ListPerf.nestedGridHeight(
          itemCount: videos.length,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          crossAxisExtent: constraints.maxWidth,
        );
        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspect,
            ),
            itemCount: videos.length,
            itemBuilder: (context, i) => _VideoTile(video: videos[i]),
          ),
        );
      },
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
      avatar: hashtag.videosCount > 0
          ? Text(
              formatShortCount(hashtag.videosCount),
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            )
          : null,
      backgroundColor: context.colors.surfaceElevated,
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () => context.push(
        '/shorts/hashtag/${Uri.encodeComponent(hashtag.name)}',
      ),
    );
  }
}

class _MusicTile extends StatelessWidget {
  const _MusicTile({required this.music});

  final ShortMusicEntity music;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ProGlassCard(
      tier: GlassTier.static,
      padding: const EdgeInsets.all(10),
      animateIn: false,
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(
        '/shorts/music/${Uri.encodeComponent(music.id)}'
        '?title=${Uri.encodeComponent(music.title)}',
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
                    color: context.colors.surface,
                    child: Icon(Icons.music_note,
                        color: context.colors.onSurfaceMuted),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (music.artist != null)
                  Text(
                    music.artist!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.onSurfaceMuted,
                      fontSize: 11,
                    ),
                  ),
                if (music.usageCount > 0)
                  Text(
                    '${formatShortCount(music.usageCount)} video',
                    style: TextStyle(
                      color: context.colors.onSurfaceMuted.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
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

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, this.compact = false});

  final ShortVideoEntity video;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final thumb = video.thumbnailUrl;
    final radius = compact ? 10.0 : 14.0;
    return HeroShortThumb(
      videoId: video.id,
      child: RepaintBoundary(
        child: GestureDetector(
        onTap: () => context.push('/shorts?videoId=${video.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null && thumb.isNotEmpty)
                CanlifalNetworkImage(url: thumb, fit: BoxFit.cover)
              else
                ColoredBox(
                  color: context.colors.surfaceElevated,
                  child: Center(
                    child: Icon(Icons.play_circle_outline,
                        color: context.colors.onSurfaceMuted),
                  ),
                ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact && video.viewsCount > 0)
                      Text(
                        '${formatShortCount(video.viewsCount)} izlenme',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    Text(
                      video.description?.trim().isNotEmpty == true
                          ? video.description!.trim()
                          : '@${video.author?.username ?? 'video'}',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
