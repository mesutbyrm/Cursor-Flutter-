import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import '../utils/shorts_api_message.dart';
import '../utils/shorts_count_format.dart';
import 'short_comments_sheet.dart';
import 'short_share_sheet.dart';

class ShortVideoActionsRail extends ConsumerStatefulWidget {
  const ShortVideoActionsRail({
    super.key,
    required this.video,
    required this.onVideoUpdated,
  });

  final ShortVideoEntity video;
  final ValueChanged<ShortVideoEntity> onVideoUpdated;

  @override
  ConsumerState<ShortVideoActionsRail> createState() =>
      _ShortVideoActionsRailState();
}

class _ShortVideoActionsRailState extends ConsumerState<ShortVideoActionsRail> {
  ShortVideoEntity get video => widget.video;

  Future<void> _runInteraction(
    Future<void> Function() action, {
    String? errorPrefix,
  }) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      showShortsSnackBar(
        context,
        errorPrefix != null ? '$errorPrefix: ${shortsErrorMessage(e)}' : shortsErrorMessage(e),
      );
    }
  }

  Future<void> _toggleLike() async {
    final optimistic = video.copyWith(
      likedByMe: !video.likedByMe,
      likesCount: video.likedByMe
          ? (video.likesCount > 0 ? video.likesCount - 1 : 0)
          : video.likesCount + 1,
    );
    widget.onVideoUpdated(optimistic);
    await _runInteraction(() async {
      final res = await ref.read(shortsRepositoryProvider).toggleLike(video.id);
      widget.onVideoUpdated(
        video.copyWith(likedByMe: res.liked, likesCount: res.likesCount),
      );
    }, errorPrefix: 'Beğeni');
  }

  Future<void> _toggleSave() async {
    final optimistic = video.copyWith(
      savedByMe: !video.savedByMe,
      savesCount: video.savedByMe
          ? (video.savesCount > 0 ? video.savesCount - 1 : 0)
          : video.savesCount + 1,
    );
    widget.onVideoUpdated(optimistic);
    await _runInteraction(() async {
      final res = await ref.read(shortsRepositoryProvider).toggleSave(video.id);
      widget.onVideoUpdated(
        video.copyWith(savedByMe: res.saved, savesCount: res.savesCount),
      );
    }, errorPrefix: 'Kaydet');
  }

  Future<void> _openComments() async {
    final count = await showShortCommentsSheet(
      context,
      ref,
      video,
      onCountChanged: (c) => widget.onVideoUpdated(
        video.copyWith(commentsCount: c),
      ),
    );
    if (count != null) {
      widget.onVideoUpdated(video.copyWith(commentsCount: count));
    }
  }

  Future<void> _share() async {
    await showShortShareSheet(
      context,
      videoId: video.id,
      description: video.description,
      onShared: () async {
        try {
          final shares =
              await ref.read(shortsRepositoryProvider).recordShare(video.id);
          widget.onVideoUpdated(
            video.copyWith(
              sharesCount: shares > 0 ? shares : video.sharesCount + 1,
            ),
          );
        } catch (_) {}
      },
    );
  }

  void _openProfile() {
    final uid = video.userId.isNotEmpty
        ? video.userId
        : (video.author?.id ?? '');
    if (uid.isEmpty) {
      showShortsSnackBar(context, 'Profil bulunamadı.');
      return;
    }
    context.push('/user/$uid');
  }

  void _moreMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121218),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Bağlantıyı kopyala'),
              onTap: () {
                Navigator.pop(ctx);
                _share();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Bildir'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: video.likedByMe ? Icons.favorite : Icons.favorite_border,
          label: formatShortCount(video.likesCount),
          color: video.likedByMe ? Colors.redAccent : Colors.white,
          onTap: _toggleLike,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: formatShortCount(video.commentsCount),
          onTap: _openComments,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: video.savedByMe ? Icons.bookmark : Icons.bookmark_border,
          label: formatShortCount(video.savesCount),
          color: video.savedByMe ? Colors.amber : Colors.white,
          onTap: _toggleSave,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.share_outlined,
          label: formatShortCount(video.sharesCount),
          onTap: _share,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.more_horiz,
          label: 'Daha',
          onTap: _moreMenu,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _openProfile,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ShortVideoInfoOverlay extends StatelessWidget {
  const ShortVideoInfoOverlay({
    super.key,
    required this.video,
    this.onAuthorTap,
  });

  final ShortVideoEntity video;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final author = video.author;
    final desc = video.description?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (author != null)
          GestureDetector(
            onTap: onAuthorTap,
            child: Text(
              '@${author.username}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        if (video.music != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.music_note, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  video.music!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
        if (video.hashtags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              for (final tag in video.hashtags.take(4))
                GestureDetector(
                  onTap: () => context.push('/shorts/hashtag/${Uri.encodeComponent(tag)}'),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
        Text(
          '${formatShortCount(video.viewsCount)} izlenme',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
