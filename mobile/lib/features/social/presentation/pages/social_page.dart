import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/social_providers.dart';
import '../widgets/instagram/social_active_rooms.dart';
import '../widgets/instagram/social_instagram_app_bar.dart';
import '../widgets/instagram/social_instagram_post_card.dart';
import '../utils/open_social_create_post.dart';
import '../widgets/instagram/social_feed_composer.dart';
import '../widgets/instagram/social_stories_rail.dart';

/// CanlıFal Sosyal — premium mistik akış.
class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(socialNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(socialNotifierProvider.notifier).refresh(),
      ref.refresh(socialStoryRingsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialNotifierProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 88;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RepaintBoundary(child: SocialInstagramAppBar()),
            const RepaintBoundary(child: SocialStoriesRail()),
            const RepaintBoundary(child: SocialFeedComposer()),
            Expanded(
              child: DiscoverRefresh.wrap(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    social.when(
                      loading: () => SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => const RepaintBoundary(
                            child: PremiumPostSkeleton(),
                          ),
                          childCount: 3,
                        ),
                      ),
                      error: (e, _) => SliverFillRemaining(
                        child: DiscoverEmptyState(
                          icon: Icons.cloud_off_rounded,
                          message: ApiException.userMessage(e),
                          actionLabel: 'Tekrar dene',
                          action: () => ref
                              .read(socialNotifierProvider.notifier)
                              .refresh(),
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
                              action: () => openSocialCreatePost(context, ref),
                            ),
                          );
                        }
                        return SliverMainAxisGroup(
                          slivers: [
                            SliverToBoxAdapter(
                              child: RepaintBoundary(
                                child: SocialInstagramPostCard(
                                  post: posts.first,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: RepaintBoundary(
                                child: SocialActiveRooms(),
                              ),
                            ),
                            if (posts.length > 1)
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => RepaintBoundary(
                                    child: SocialInstagramPostCard(
                                      post: posts[i + 1],
                                    ),
                                  ),
                                  childCount: posts.length - 1,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: bottom)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
