import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/canlifal_tokens.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import 'social_post_caption.dart';

/// CanlıFal Sosyal akış kartı — doğrulanmış başlık, metin, CTA, etkileşim sayıları.
class SocialInstagramPostCard extends StatefulWidget {
  const SocialInstagramPostCard({super.key, required this.post});

  final PostEntity post;

  @override
  State<SocialInstagramPostCard> createState() =>
      _SocialInstagramPostCardState();
}

class _SocialInstagramPostCardState extends State<SocialInstagramPostCard> {
  var _liked = false;

  PostEntity get post => widget.post;

  /// Sosyal akışta fal CTA her zaman görünür (tasarım).
  bool get _showFortuneCta => true;

  @override
  Widget build(BuildContext context) {
    final likeCount = post.likesCount + (_liked ? 1 : 0);
    final shareCount = post.viewCount > 0 ? post.viewCount : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PostHeader(
          post: post,
          onProfile: () => context.push('/user/${post.author.id}'),
        ),
        if ((post.caption?.trim().isNotEmpty ?? false))
          SocialPostCaption(post: post, inlineBodyOnly: true),
        _PostMediaBlock(
          post: post,
          showFortuneCta: _showFortuneCta,
          onFortuneTap: () => _openFortune(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              _ActionWithCount(
                icon: _liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _liked ? AppColors.accentPink : AppColors.textPrimary,
                count: likeCount,
                onTap: () => setState(() => _liked = !_liked),
              ),
              const SizedBox(width: 20),
              _ActionWithCount(
                icon: Icons.mode_comment_outlined,
                count: post.commentsCount,
                onTap: () => _showCommentsHint(context),
              ),
              const Spacer(),
              _ActionWithCount(
                icon: Icons.ios_share_rounded,
                count: shareCount,
                hideZeroCount: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paylaşım yakında')),
                  );
                },
              ),
            ],
          ),
        ),
        if (post.commentsCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: GestureDetector(
              onTap: () => _showCommentsHint(context),
              child: Text(
                '${post.commentsCount} yorumun tümünü gör',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.95),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  void _openFortune(BuildContext context) {
    final slug = post.fortuneType;
    if (slug != null && slug.isNotEmpty) {
      context.push('/fortune/$slug');
    } else {
      context.push('/fortune');
    }
  }

  void _showCommentsHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yorumlar yakında')),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.onProfile});

  final PostEntity post;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final verified = _isVerifiedAuthor(post);
    final timeLabel = post.createdAt != null
        ? _formatTimeShort(post.createdAt!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfile,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
                boxShadow: AppColors.glowShadow(
                  AppColors.accentPurple,
                  blur: 12,
                ),
              ),
              child: UserAvatar(url: post.author.avatarUrl, radius: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onProfile,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.author.display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.diamondBlue.withValues(alpha: 0.95),
                        ),
                      ],
                    ],
                  ),
                  if (timeLabel != null)
                    Row(
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.public_rounded,
                          size: 12,
                          color: AppColors.textMuted.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 26),
            color: AppColors.textPrimary,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  static bool _isVerifiedAuthor(PostEntity post) {
    final u = post.author.username.toLowerCase();
    final d = post.author.display.toLowerCase();
    return u.contains('admin') ||
        d.contains('admin') ||
        d.contains('canlıfal') ||
        d.contains('canlifal');
  }

  static String _formatTimeShort(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'az önce';
    if (d.inHours < 1) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} sa önce';
    if (d.inDays < 7) return '${d.inDays} gün önce';
    return '${t.day}.${t.month}.${t.year}';
  }
}

class _PostMediaBlock extends StatelessWidget {
  const _PostMediaBlock({
    required this.post,
    required this.showFortuneCta,
    required this.onFortuneTap,
  });

  final PostEntity post;
  final bool showFortuneCta;
  final VoidCallback onFortuneTap;

  @override
  Widget build(BuildContext context) {
    final hasMedia = post.mediaUrl != null && post.mediaUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasMedia)
                CachedNetworkImage(
                  imageUrl: post.mediaUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _MysticMediaPlaceholder(),
                  errorWidget: (_, _, _) => const _MysticMediaPlaceholder(),
                )
              else
                const _MysticMediaPlaceholder(),
              if (showFortuneCta)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      child: Center(
                        child: _FortuneCtaButton(onTap: onFortuneTap),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FortuneCtaButton extends StatelessWidget {
  const _FortuneCtaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: tokens.brandGradient,
            boxShadow: AppColors.glowShadow(AppColors.accentPurple, blur: 18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🃏', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Falına Bak',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MysticMediaPlaceholder extends StatelessWidget {
  const _MysticMediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0F3D),
            Color(0xFF2D1548),
            Color(0xFF0B0B1E),
          ],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔮', style: TextStyle(fontSize: 56)),
          SizedBox(height: 8),
          Text('🕯️', style: TextStyle(fontSize: 28)),
          SizedBox(height: 4),
          Text('🃏', style: TextStyle(fontSize: 32)),
        ],
      ),
    );
  }
}

class _ActionWithCount extends StatelessWidget {
  const _ActionWithCount({
    required this.icon,
    required this.onTap,
    this.count = 0,
    this.color = AppColors.textPrimary,
    this.hideZeroCount = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int count;
  final Color color;
  final bool hideZeroCount;

  @override
  Widget build(BuildContext context) {
    final showCount = count > 0 || !hideZeroCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            if (showCount && count > 0) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(count),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
