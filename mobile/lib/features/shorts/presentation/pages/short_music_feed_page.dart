import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/hero_tags.dart';
import '../providers/shorts_providers.dart';
import '../widgets/shorts_premium_theme.dart';

/// Müzik detayı — bu parçayı kullanan kısa videolar.
class ShortMusicFeedPage extends ConsumerStatefulWidget {
  const ShortMusicFeedPage({
    super.key,
    required this.musicId,
    this.title,
  });

  final String musicId;
  final String? title;

  @override
  ConsumerState<ShortMusicFeedPage> createState() => _ShortMusicFeedPageState();
}

class _ShortMusicFeedPageState extends ConsumerState<ShortMusicFeedPage> {
  Future<void> _refresh() async {
    ref.invalidate(shortMusicVideosProvider(widget.musicId));
    await ref.read(shortMusicVideosProvider(widget.musicId).future);
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(shortMusicVideosProvider(widget.musicId));

    return Scaffold(
      backgroundColor: ShortsPremiumTheme.chromeBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title?.trim().isNotEmpty == true ? widget.title! : 'Müzik'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: videos.when(
          loading: () => const PremiumShortGridSkeleton(count: 8),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: Center(child: Text('$e')),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: Center(
                      child: Text(
                        'Bu müzikle video yok',
                        style: TextStyle(color: context.colors.onSurfaceMuted),
                      ),
                    ),
                  ),
                ],
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 9 / 14,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final v = list[i];
                return ListPerf.repaint(
                  HeroShortThumb(
                    videoId: v.id,
                    child: GestureDetector(
                      onTap: () => context.push('/shorts?videoId=${v.id}'),
                      child: ClipRRect(
                        borderRadius: ShortsPremiumTheme.tileRadius,
                        child: v.thumbnailUrl != null
                            ? CanlifalNetworkImage(
                                url: v.thumbnailUrl!,
                                fit: BoxFit.cover,
                              )
                            : ColoredBox(
                                color: context.colors.surfaceElevated,
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: context.colors.onSurfaceMuted,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
