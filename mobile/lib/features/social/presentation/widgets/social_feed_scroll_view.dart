import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../providers/social_providers.dart';
import '../utils/social_feed_layout.dart';
import '../widgets/instagram/social_active_rooms.dart';
import '../widgets/instagram/social_instagram_post_card.dart';
import '../providers/social_composer_providers.dart';

/// Sosyal akış — yalnızca feed provider'ını izler; app bar/composer etkilenmez.
class SocialFeedScrollView extends ConsumerWidget {
  const SocialFeedScrollView({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.bottomPadding,
  });

  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialNotifierProvider);

    return DiscoverRefresh.wrap(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        scrollCacheExtent: ScrollPerf.scrollCache(ScrollPerf.feedCacheExtent),
        physics: PremiumMotion.listPhysics,
        slivers: [
          social.when(
            loading: () => SliverList.builder(
              itemCount: 3,
              itemBuilder: (_, _) => const RepaintBoundary(
                child: PremiumPostSkeleton(),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: DiscoverEmptyState(
                icon: Icons.cloud_off_rounded,
                message: ApiException.userMessage(e),
                actionLabel: 'Tekrar dene',
                action: () => ref.read(socialNotifierProvider.notifier).refresh(),
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: DiscoverEmptyState(
                    icon: Icons.photo_camera_outlined,
                    message: Env.useNextAuth
                        ? 'Henüz paylaşım yok.\nİlk gönderini paylaş veya canlifal.com oturumunu kontrol et.'
                        : 'Henüz paylaşım yok.\nİlk gönderini şimdi paylaş.',
                    actionLabel: 'Paylaşım oluştur',
                    action: () => ref
                        .read(socialComposerExpandedProvider.notifier)
                        .state = true,
                  ),
                );
              }
              final feedCount = SocialFeedLayout.itemCount(posts.length);
              return SliverList.builder(
                itemCount: feedCount,
                itemBuilder: (context, i) {
                  final postIdx = SocialFeedLayout.postIndexAt(i, posts.length);
                  if (postIdx != null) {
                    return ScrollPerf.item(
                      SocialInstagramPostCard(
                        post: posts[postIdx],
                      ),
                    );
                  }
                  return const RepaintBoundary(
                    child: SocialActiveRooms(embeddedInFeed: true),
                  );
                },
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
        ],
      ),
    );
  }
}
