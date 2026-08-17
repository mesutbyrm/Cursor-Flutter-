import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../providers/social_providers.dart';
import '../utils/open_social_create_post.dart';
import '../utils/social_feed_layout.dart';
import '../widgets/instagram/social_active_rooms.dart';
import '../widgets/instagram/social_instagram_post_card.dart';
import '../widgets/social_feed_end_banner.dart';

/// Sosyal akış — yalnızca feed provider'ını izler; app bar/composer etkilenmez.
class SocialFeedScrollView extends ConsumerWidget {
  const SocialFeedScrollView({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.bottomPadding,
    this.onPostPublished,
  });

  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final double bottomPadding;
  final VoidCallback? onPostPublished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialNotifierProvider);
    final live = ref.watch(liveStreamsProvider);
    final rooms = ref.watch(voiceRoomsProvider);
    final showRoomStrips = socialActiveRoomsAvailable(
      streams: live.valueOrNull,
      rooms: rooms.valueOrNull,
    );

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
                    action: () => openSocialCreatePost(
                      context,
                      ref,
                      onPublished: onPostPublished,
                    ),
                  ),
                );
              }
              final notifier = ref.read(socialNotifierProvider.notifier);
              final loadingMore = notifier.isLoadingMore;
              final atEnd = !notifier.hasMore && !loadingMore;
              final feedCount = SocialFeedLayout.itemCount(
                posts.length,
                includeRoomStrips: showRoomStrips,
              );
              final trailingSlots = (loadingMore ? 1 : 0) + (atEnd ? 1 : 0);
              return SliverList.builder(
                itemCount: feedCount + trailingSlots,
                itemBuilder: (context, i) {
                  if (i >= feedCount) {
                    if (loadingMore && i == feedCount) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return const SocialFeedEndBanner();
                  }
                  final postIdx = SocialFeedLayout.postIndexAt(
                    i,
                    posts.length,
                    includeRoomStrips: showRoomStrips,
                  );
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
