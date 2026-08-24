import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/presentation/providers/staff_access_provider.dart';

import 'package:video_player/video_player.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/performance/effects_perf.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/network/connectivity/connectivity_service.dart';
import '../../data/shorts_offline_action_queue.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import '../utils/short_studio_launch.dart';
import '../utils/shorts_api_message.dart';
import '../utils/shorts_count_format.dart';
import 'short_comments_sheet.dart';
import 'short_gift_sheet.dart';
import 'short_share_sheet.dart';
import 'short_video_analytics_sheet.dart';
import 'short_video_pip_overlay.dart';
import 'shorts_profile_content.dart';

class ShortVideoActionsRail extends ConsumerStatefulWidget {
  const ShortVideoActionsRail({
    super.key,
    required this.video,
    required this.onVideoUpdated,
    this.videoController,
  });

  final ShortVideoEntity video;
  final ValueChanged<ShortVideoEntity> onVideoUpdated;
  final VideoPlayerController? videoController;

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
        errorPrefix != null
            ? '$errorPrefix: ${shortsErrorMessage(e)}'
            : shortsErrorMessage(e),
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
      if (!ref.read(isOnlineProvider)) {
        await ShortsOfflineActionQueue.instance.enqueueLike(
          video.id,
          liked: optimistic.likedByMe,
        );
        return;
      }
      final res = await ref.read(shortsRepositoryProvider).toggleLike(video.id);
      widget.onVideoUpdated(
        video.copyWith(likedByMe: res.liked, likesCount: res.likesCount),
      );
      await FirebaseBootstrap.logEvent(
        'short_like',
        parameters: {'video_id': video.id, 'liked': res.liked},
      );
    }, errorPrefix: 'Beğeni');
    if (mounted && ref.read(isOnlineProvider) == false) return;
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
      if (!ref.read(isOnlineProvider)) {
        await ShortsOfflineActionQueue.instance.enqueueSave(
          video.id,
          saved: optimistic.savedByMe,
        );
        return;
      }
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
      video: video,
      ref: ref,
      onShared: () async {
        try {
          final shares =
              await ref.read(shortsRepositoryProvider).recordShare(video.id);
          widget.onVideoUpdated(
            video.copyWith(
              sharesCount: shares > 0 ? shares : video.sharesCount + 1,
            ),
          );
          await FirebaseBootstrap.logEvent(
            'short_share',
            parameters: {'video_id': video.id},
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

  Future<void> _toggleFollow() async {
    final uid = video.userId.isNotEmpty
        ? video.userId
        : (video.author?.id ?? '');
    if (uid.isEmpty) return;
    final wasFollowing = video.authorFollowedByMe;
    widget.onVideoUpdated(video.copyWith(authorFollowedByMe: !wasFollowing));
    await _runInteraction(() async {
      final repo = ref.read(profileRepositoryProvider);
      if (wasFollowing) {
        await repo.unfollow(uid);
      } else {
        await repo.follow(uid);
      }
      ref.invalidate(shortVideoProfileStatsProvider(uid));
    }, errorPrefix: 'Takip');
  }

  void _startDuet() {
    openShortStudio(
      GoRouter.of(context),
      mode: ShortStudioMode.duet,
      sourceVideoId: video.id,
    );
  }

  void _startRemix() {
    openShortStudio(
      GoRouter.of(context),
      mode: ShortStudioMode.remix,
      sourceVideoId: video.id,
    );
  }

  void _activatePip() {
    final c = widget.videoController;
    if (c == null) {
      showShortsSnackBar(context, 'PiP için video oynatıcı hazır değil.');
      return;
    }
    ref.read(shortVideoPipProvider.notifier).activate(
          video: video,
          controller: c,
        );
    showShortsSnackBar(context, 'Mini oynatıcı açıldı — sürükleyebilirsiniz.');
  }

  Future<void> _deleteOwnVideo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Videoyu sil'),
        content: const Text('Bu video kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _runInteraction(() async {
      await ref.read(shortsRepositoryProvider).deleteVideo(video.id);
      ref.invalidate(shortsFeedProvider);
      if (mounted) showShortsSnackBar(context, 'Video silindi.');
    }, errorPrefix: 'Silme');
  }

  void _startVideoReply() {
    openShortStudio(
      GoRouter.of(context),
      mode: ShortStudioMode.videoReply,
      sourceVideoId: video.id,
    );
  }

  Future<void> _openGifts() async {
    await showShortGiftSheet(context, ref, video);
  }

  void _moreMenu() {
    final me = ref.read(currentUserIdProvider);
    final isOwner = me != null && me == video.userId;
    final isAdmin = ref.read(staffAccessProvider).isSiteAdmin;
    final canManage = isOwner || isAdmin;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121218),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (video.allowDuet) ...[
              ListTile(
                leading: const Icon(Icons.call_split),
                title: const Text('Düet yap'),
                onTap: () {
                  Navigator.pop(ctx);
                  _startDuet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.music_note_outlined),
                title: const Text('Remix — bu sesi kullan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _startRemix();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video ile yanıtla'),
              onTap: () {
                Navigator.pop(ctx);
                _startVideoReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_in_picture_alt_outlined),
              title: const Text('Picture in Picture'),
              onTap: () {
                Navigator.pop(ctx);
                _activatePip();
              },
            ),
            if (canManage)
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Video analitikleri'),
                onTap: () {
                  Navigator.pop(ctx);
                  showShortVideoAnalyticsSheet(context, ref, video);
                },
              ),
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
              onTap: () {
                Navigator.pop(ctx);
                openReportFlow(
                  context,
                  ReportTarget(
                    type: ReportTargetType.shortVideo,
                    targetId: video.id,
                    displayTitle: video.description ?? video.author?.username,
                    contextLabel: 'Kısa video',
                  ),
                );
              },
            ),
            if (canManage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                  isAdmin && !isOwner ? 'Videoyu sil (admin)' : 'Videoyu sil',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteOwnVideo();
                },
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
          icon: Icons.card_giftcard_outlined,
          label: 'Hediye',
          color: Colors.amber,
          onTap: _openGifts,
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
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            GestureDetector(
              onTap: _openProfile,
              child: UserAvatar(
                url: video.author?.avatarUrl,
                radius: 22,
              ),
            ),
            if (!video.authorFollowedByMe)
              Positioned(
                bottom: -6,
                child: GestureDetector(
                  onTap: _toggleFollow,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
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
          EffectsPerf.chromeBar(
            context: context,
            sigma: 8,
            borderRadius: BorderRadius.circular(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: color, size: 26),
            ),
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
    this.onDuetTap,
  });

  final ShortVideoEntity video;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onDuetTap;

  @override
  Widget build(BuildContext context) {
    final author = video.author;
    final desc = video.description?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (video.duetOfId != null)
          GestureDetector(
            onTap: onDuetTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_split, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Düet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (video.replyToVideoId != null)
          GestureDetector(
            onTap: () => context.push('/shorts?videoId=${video.replyToVideoId}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Video yanıt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (author != null)
          GestureDetector(
            onTap: onAuthorTap,
            child: Row(
              children: [
                Text(
                  '@${author.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (author.isVerified) ...[
                  const SizedBox(width: 4),
                  const ShortsVerifiedBadge(size: 16),
                ],
              ],
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
