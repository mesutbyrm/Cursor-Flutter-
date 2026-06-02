import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../social/presentation/providers/user_social_posts_notifier.dart';
import '../../../social/presentation/widgets/instagram/social_post_caption.dart';

/// TikTok tarzı 3 sütun paylaşım ızgarası — API sayfalama.
class UserPostsTikTokGrid extends ConsumerStatefulWidget {
  const UserPostsTikTokGrid({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserPostsTikTokGrid> createState() =>
      _UserPostsTikTokGridState();
}

class _UserPostsTikTokGridState extends ConsumerState<UserPostsTikTokGrid> {
  @override
  Widget build(BuildContext context) {
    final postsAsync =
        ref.watch(userSocialPostsNotifierProvider(widget.userId));

    return postsAsync.when(
      loading: () => Padding(
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
          style: TextStyle(color: context.colors.onSurfaceMuted.withValues(alpha: 0.9)),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Henüz paylaşım yok',
                style: TextStyle(
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final hasMore = ref
            .read(userSocialPostsNotifierProvider(widget.userId).notifier)
            .hasMore;

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification &&
                n.metrics.pixels >=
                    n.metrics.maxScrollExtent - ListPerf.preloadThresholdPx) {
              ref
                  .read(userSocialPostsNotifierProvider(widget.userId).notifier)
                  .loadMore();
            }
            return false;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return ListPerf.repaint(
                    _TikTokPostTile(post: posts[index]),
                  );
                },
              ),
              if (hasMore)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TikTokPostTile extends StatelessWidget {
  const _TikTokPostTile({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final hasMedia =
        post.mediaUrl != null && post.mediaUrl!.trim().isNotEmpty;
    final caption = post.caption?.trim() ?? '';

    return GestureDetector(
      onTap: () => _openPostSheet(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0F3D),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasMedia)
              CachedNetworkImage(
                imageUrl: post.mediaUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _textBackdrop(caption),
              )
            else
              _textBackdrop(caption),
            if (caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    caption.length > socialCaptionPreviewChars
                        ? '${caption.substring(0, socialCaptionPreviewChars)}…'
                        : caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            if (post.likesCount > 0)
              Positioned(
                left: 6,
                top: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 2),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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

  Widget _textBackdrop(String caption) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1548), Color(0xFF14102A)],
        ),
      ),
      child: Text(
        caption.isEmpty ? '✨' : caption,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: AppThemeColors.dark.onSurface,
        ),
      ),
    );
  }

  void _openPostSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final caption = post.caption?.trim() ?? '';
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: CachedNetworkImage(
                      imageUrl: post.mediaUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (caption.isNotEmpty) ...[
                SizedBox(height: 16),
                SocialPostTextPreview(text: caption),
              ],
            ],
          ),
        );
      },
    );
  }
}
