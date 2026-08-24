import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../social/presentation/providers/user_social_posts_notifier.dart';
import '../../../social/presentation/widgets/instagram/social_instagram_post_card.dart';

/// Paylaşım duvarı — parent [CustomScrollView] içinde tek scroll olarak kullanılır.
class UserPostsTimelineSliver extends ConsumerStatefulWidget {
  const UserPostsTimelineSliver({
    super.key,
    required this.userId,
    this.focusPostId,
  });

  final String userId;
  final String? focusPostId;

  @override
  ConsumerState<UserPostsTimelineSliver> createState() =>
      _UserPostsTimelineSliverState();
}

/// Geriye dönük alias — yalnızca sliver kullanımına yönlendirir.
@Deprecated('Use UserPostsTimelineSliver inside CustomScrollView')
typedef UserPostsTimeline = UserPostsTimelineSliver;

class _UserPostsTimelineSliverState
    extends ConsumerState<UserPostsTimelineSliver> {
  final _keys = <String, GlobalKey>{};
  var _scrolledToFocus = false;

  GlobalKey _keyFor(String postId) =>
      _keys.putIfAbsent(postId, GlobalKey.new);

  void _scrollToFocus(List<PostEntity> posts) {
    final focusId = widget.focusPostId?.trim();
    if (focusId == null || focusId.isEmpty || _scrolledToFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _keys[focusId];
      final ctx = key?.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
        _scrolledToFocus = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync =
        ref.watch(userSocialPostsNotifierProvider(widget.userId));

    return postsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Column(
          children: [
            PremiumPostSkeleton(),
            PremiumPostSkeleton(),
          ],
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: AppErrorView.fromError(
          e,
          compact: true,
          onRetry: () => ref.invalidate(
            userSocialPostsNotifierProvider(widget.userId),
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Henüz paylaşım yok',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }

        _scrollToFocus(posts);

        final hasMore = ref
            .read(userSocialPostsNotifierProvider(widget.userId).notifier)
            .hasMore;

        return SliverMainAxisGroup(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = posts[index];
                  return ListPerf.repaint(
                    KeyedSubtree(
                      key: _keyFor(post.id),
                      child: SocialInstagramPostCard(
                        post: post,
                        openProfileOnTap: false,
                      ),
                    ),
                  );
                },
                childCount: posts.length,
              ),
            ),
            if (hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TextButton(
                    onPressed: () => ref
                        .read(
                          userSocialPostsNotifierProvider(widget.userId)
                              .notifier,
                        )
                        .loadMore(),
                    child: const Text('Daha fazla yükle'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
