import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/widgets/hero_tags.dart';
import '../providers/shorts_providers.dart';
import '../widgets/shorts_premium_theme.dart';

class ShortHashtagPage extends ConsumerWidget {
  const ShortHashtagPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(shortHashtagVideosProvider(name));

    return Scaffold(
      backgroundColor: ShortsPremiumTheme.chromeBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('#${name.replaceAll('#', '')}'),
      ),
      body: videos.when(
        loading: () => const PremiumShortGridSkeleton(count: 8),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Bu hashtag ile video yok',
                style: TextStyle(color: context.colors.onSurfaceMuted),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            physics: PremiumMotion.listPhysics,
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
    );
  }
}
