import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import 'short_comments_sheet.dart';

class ShortVideoActionsRail extends ConsumerWidget {
  const ShortVideoActionsRail({
    super.key,
    required this.video,
    required this.onVideoUpdated,
  });

  final ShortVideoEntity video;
  final ValueChanged<ShortVideoEntity> onVideoUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: video.likedByMe ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(video.likesCount),
          color: video.likedByMe ? Colors.redAccent : Colors.white,
          onTap: () => _toggleLike(ref),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: _formatCount(video.commentsCount),
          onTap: () => _openComments(context, ref),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Paylaş',
          onTap: () => _share(video),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.person_outline,
          label: 'Profil',
          onTap: () => context.push('/user/${video.userId}'),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Future<void> _toggleLike(WidgetRef ref) async {
    try {
      final res =
          await ref.read(shortsRepositoryProvider).toggleLike(video.id);
      onVideoUpdated(
        video.copyWith(likedByMe: res.liked, likesCount: res.likesCount),
      );
    } catch (_) {}
  }

  Future<void> _openComments(BuildContext context, WidgetRef ref) async {
    final count = await showShortCommentsSheet(context, ref, video);
    if (count != null) {
      onVideoUpdated(video.copyWith(commentsCount: count));
    }
  }

  void _share(ShortVideoEntity v) {
    final text = [
      if (v.description?.trim().isNotEmpty == true) v.description!.trim(),
      v.videoUrl,
    ].join('\n');
    SharePlus.instance.share(ShareParams(text: text));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ShortVideoInfoOverlay extends StatelessWidget {
  const ShortVideoInfoOverlay({super.key, required this.video});

  final ShortVideoEntity video;

  @override
  Widget build(BuildContext context) {
    final author = video.author;
    final desc = video.description?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (author != null)
          Text(
            '@${author.username}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        if (desc != null && desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.play_arrow_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text(
              '${video.viewsCount} izlenme',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
