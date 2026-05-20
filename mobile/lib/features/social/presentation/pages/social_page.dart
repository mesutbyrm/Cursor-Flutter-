import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/social_providers.dart';
import '../widgets/instagram/social_instagram_app_bar.dart';
import '../widgets/instagram/social_instagram_post_card.dart';

/// Sosyal akış — Instagram tarzı UI, veri: canlifal.com API.
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
    await ref.read(socialNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialNotifierProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 88;

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SocialInstagramAppBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppDesign.accentPink,
                backgroundColor: AppDesign.bgPurpleGlow,
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    social.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(child: DiscoverAccentLoader()),
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
                                  ? 'Henüz paylaşım yok.\nGiriş yaptıysanız canlifal.com ile aynı oturumu kullanın.'
                                  : 'Henüz paylaşım yok.',
                            ),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => SocialInstagramPostCard(
                              post: posts[i],
                            ),
                            childCount: posts.length,
                          ),
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
