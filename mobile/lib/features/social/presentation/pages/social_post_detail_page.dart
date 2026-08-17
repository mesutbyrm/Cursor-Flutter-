import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/config/env.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../utils/social_caption_link_parser.dart';
import '../utils/social_feed_refresh.dart';
import '../utils/social_post_resolver.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../providers/social_providers.dart';
import '../widgets/instagram/social_instagram_post_card.dart';
import '../widgets/instagram/social_post_comments_sheet.dart';

/// Tek gönderi detayı — `GET /api/social/posts/{postId}` (kılavuz §9.10).
class SocialPostDetailPage extends ConsumerWidget {
  const SocialPostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));
    final feedPosts = ref.watch(socialNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text('Gönderi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Paylaş',
            onPressed: () {
              final caption = resolveSocialPostForDetail(
                feedPosts: feedPosts,
                remotePost: postAsync.valueOrNull,
                postId: postId,
              )?.caption;
              final text = buildSocialPostShareText(
                postId: postId,
                caption: caption,
                siteOrigin: Env.siteOrigin,
              );
              SharePlus.instance.share(
                ShareParams(text: text, subject: 'Canlifal gönderisi'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Yorumlar',
            onPressed: () => SocialPostCommentsSheet.show(
              context,
              postId: postId,
              initialCount: resolveSocialPostForDetail(
                    feedPosts: feedPosts,
                    remotePost: postAsync.valueOrNull,
                    postId: postId,
                  )?.commentsCount ??
                  0,
            ),
          ),
        ],
      ),
      body: postAsync.when(
        loading: () {
          final cached = findSocialFeedPost(feedPosts, postId);
          if (cached != null) {
            return _PostDetailBody(
              post: cached,
              postId: postId,
              isRefreshing: true,
            );
          }
          return const PremiumPostSkeleton();
        },
        error: (e, _) {
          final cached = findSocialFeedPost(feedPosts, postId);
          if (cached != null) {
            return _PostDetailBody(post: cached, postId: postId);
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ApiException.userMessage(e),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => refreshSocialPostDetail(ref, postId),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (remote) {
          final post = resolveSocialPostForDetail(
            feedPosts: feedPosts,
            remotePost: remote,
            postId: postId,
          );
          if (post == null) {
            return Center(
              child: Text(
                'Gönderi bulunamadı',
                style: TextStyle(color: context.colors.onSurfaceMuted),
              ),
            );
          }
          return _PostDetailBody(post: post, postId: postId);
        },
      ),
    );
  }
}

class _PostDetailBody extends ConsumerWidget {
  const _PostDetailBody({
    required this.post,
    required this.postId,
    this.isRefreshing = false,
  });

  final PostEntity post;
  final String postId;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedPosts = ref.watch(socialNotifierProvider).valueOrNull;
    final display = mergeSocialPostDisplay(
      primary: post,
      feedOverlay: findSocialFeedPost(feedPosts, postId),
    );

    return RefreshIndicator(
      onRefresh: () => refreshSocialPostDetail(ref, postId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (isRefreshing)
            const LinearProgressIndicator(minHeight: 2),
          SocialInstagramPostCard(
            post: display,
            openProfileOnTap: true,
            onDeleted: () {
              if (context.mounted) context.pop();
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.mode_comment_outlined),
            title: const Text('Yorumları gör'),
            subtitle: Text('${display.commentsCount} yorum'),
            onTap: () => SocialPostCommentsSheet.show(
              context,
              postId: postId,
              initialCount: display.commentsCount,
            ),
          ),
        ],
      ),
    );
  }
}
