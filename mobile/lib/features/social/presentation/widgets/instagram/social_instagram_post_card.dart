import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import 'social_post_caption.dart';

/// Instagram akış kartı — `/api/social/posts` verisi.
class SocialInstagramPostCard extends StatefulWidget {
  const SocialInstagramPostCard({super.key, required this.post});

  final PostEntity post;

  @override
  State<SocialInstagramPostCard> createState() =>
      _SocialInstagramPostCardState();
}

class _SocialInstagramPostCardState extends State<SocialInstagramPostCard> {
  var _liked = false;
  var _saved = false;

  PostEntity get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final likeCount = post.likesCount + (_liked ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PostHeader(
          post: post,
          onProfile: () => context.push('/user/${post.author.id}'),
        ),
        if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
          _PostMedia(url: post.mediaUrl!)
        else
          const _TextOnlyPlaceholder(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _ActionIcon(
                icon: _liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _liked ? AppDesign.accentPink : AppDesign.textPrimary,
                onTap: () => setState(() => _liked = !_liked),
              ),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.mode_comment_outlined,
                onTap: () => _showCommentsHint(context),
              ),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.send_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paylaşım yakında')),
                  );
                },
              ),
              const Spacer(),
              _ActionIcon(
                icon: _saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: _saved ? AppDesign.accentCyan : AppDesign.textPrimary,
                onTap: () => setState(() => _saved = !_saved),
              ),
            ],
          ),
        ),
        if (likeCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              '$likeCount beğenme',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        SocialPostCaption(post: post),
        if (post.commentsCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: GestureDetector(
              onTap: () => _showCommentsHint(context),
              child: Text(
                '${post.commentsCount} yorumun tümünü gör',
                style: TextStyle(
                  color: AppDesign.textMuted.withValues(alpha: 0.95),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        if (post.createdAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Text(
              _formatTime(post.createdAt!),
              style: TextStyle(
                color: AppDesign.textMuted.withValues(alpha: 0.85),
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          )
        else
          const SizedBox(height: 14),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  void _showCommentsHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yorumlar yakında')),
    );
  }

  static String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'AZ ÖNCE';
    if (d.inHours < 1) return '${d.inMinutes} DAKİKA ÖNCE';
    if (d.inHours < 24) return '${d.inHours} SAAT ÖNCE';
    if (d.inDays < 7) return '${d.inDays} GÜN ÖNCE';
    return '${t.day} ${_monthTr(t.month)}';
  }

  static String _monthTr(int m) {
    const names = [
      'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ',
      'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA',
    ];
    return names[m.clamp(1, 12) - 1];
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.onProfile});

  final PostEntity post;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfile,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppDesign.heroGradient,
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
                  Text(
                    post.author.display,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  if (post.fortuneType != null && post.fortuneType!.isNotEmpty)
                    Text(
                      _fortuneLabel(post.fortuneType!),
                      style: const TextStyle(
                        color: AppDesign.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 26),
            color: AppDesign.textPrimary,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  static String _fortuneLabel(String type) {
    return switch (type) {
      'kahve-fali' => 'Kahve falı',
      'tarot' => 'Tarot',
      'astroloji' => 'Astroloji',
      _ => type,
    };
  }
}

class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, _) => Container(
          color: const Color(0xFF14141C),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: const Color(0xFF14141C),
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppDesign.textMuted,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _TextOnlyPlaceholder extends StatelessWidget {
  const _TextOnlyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: const Color(0xFF1A0F32),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Icon(
          Icons.article_outlined,
          size: 56,
          color: AppDesign.textMuted,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    this.onTap,
    this.color = AppDesign.textPrimary,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }
}
