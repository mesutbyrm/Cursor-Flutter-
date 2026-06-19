import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/domain/entities/post_entity.dart';
import '../../presentation/widgets/instagram/social_instagram_post_card.dart';
import '../providers/user_social_posts_notifier.dart';

/// Facebook tarzı dikey paylaşım duvarı — profil sayfasında.
class UserPostsTimeline extends ConsumerStatefulWidget {
  const UserPostsTimeline({
    super.key,
    required this.userId,
    this.focusPostId,
  });

  final String userId;
  final String? focusPostId;

  @override
  ConsumerState<UserPostsTimeline> createState() => _UserPostsTimelineState();
}

class _UserPostsTimelineState extends ConsumerState<UserPostsTimeline> {
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
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Paylaşımlar yüklenemedi',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Henüz paylaşım yok',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        _scrollToFocus(posts);

        final hasMore = ref
            .read(userSocialPostsNotifierProvider(widget.userId).notifier)
            .hasMore;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final post in posts)
              KeyedSubtree(
                key: _keyFor(post.id),
                child: SocialInstagramPostCard(
                  post: post,
                  openProfileOnTap: false,
                ),
              ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: TextButton(
                  onPressed: () => ref
                      .read(
                        userSocialPostsNotifierProvider(widget.userId).notifier,
                      )
                      .loadMore(),
                  child: const Text('Daha fazla yükle'),
                ),
              ),
          ],
        );
      },
    );
  }
}
