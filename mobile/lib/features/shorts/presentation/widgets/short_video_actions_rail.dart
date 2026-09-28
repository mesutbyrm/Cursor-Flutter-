import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/presentation/providers/staff_access_provider.dart';

import 'package:video_player/video_player.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
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
import 'short_playback_speed_sheet.dart';
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
      ShortVideoActionsRailState();
}

class ShortVideoActionsRailState extends ConsumerState<ShortVideoActionsRail> {
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

  /// Videoya uzun basınca açılan seçenekler (bildir, sil, hız, PiP…).
  void openMoreMenu() {
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
              leading: const Icon(Icons.speed_rounded),
              title: const Text('Oynatma hızı'),
              onTap: () {
                Navigator.pop(ctx);
                showShortPlaybackSpeedSheet(context, ref);
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
                    ownerUserId: video.userId,
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

  void _openMusicOrProfile() {
    final music = video.music;
    if (music != null && music.id.isNotEmpty) {
      context.push(
        '/shorts/music/${Uri.encodeComponent(music.id)}'
        '?title=${Uri.encodeComponent(music.title)}',
      );
      return;
    }
    _openProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AuthorAvatar(
          avatarUrl: video.author?.avatarUrl,
          showFollow: !video.authorFollowedByMe,
          onTap: _openProfile,
          onFollow: _toggleFollow,
        ),
        const SizedBox(height: 22),
        _ActionButton(
          icon: Icons.favorite_rounded,
          label: formatShortCount(video.likesCount),
          color: video.likedByMe ? const Color(0xFFFF2D55) : Colors.white,
          semanticLabel: video.likedByMe ? 'Beğeniyi geri al' : 'Beğen',
          onTap: _toggleLike,
        ),
        const SizedBox(height: 14),
        _ActionButton(
          icon: Icons.sms_rounded,
          label: formatShortCount(video.commentsCount),
          semanticLabel: 'Yorumlar',
          onTap: _openComments,
        ),
        const SizedBox(height: 14),
        _ActionButton(
          icon: Icons.bookmark_rounded,
          label: formatShortCount(video.savesCount),
          color: video.savedByMe ? const Color(0xFFFFC928) : Colors.white,
          semanticLabel: video.savedByMe ? 'Kaydı kaldır' : 'Kaydet',
          onTap: _toggleSave,
        ),
        const SizedBox(height: 14),
        _ActionButton(
          icon: Icons.reply_rounded,
          mirror: true,
          label: formatShortCount(video.sharesCount),
          semanticLabel: 'Paylaş',
          onTap: _share,
        ),
        const SizedBox(height: 14),
        _GiftButton(onTap: _openGifts),
        const SizedBox(height: 18),
        _MusicDisc(
          coverUrl: video.music?.coverUrl ?? video.author?.avatarUrl,
          onTap: _openMusicOrProfile,
        ),
      ],
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.avatarUrl,
    required this.showFollow,
    required this.onTap,
    required this.onFollow,
  });

  final String? avatarUrl;
  final bool showFollow;
  final VoidCallback onTap;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Semantics(
            button: true,
            label: 'Profili aç',
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B5CF6),
                ),
                child: UserAvatar(url: avatarUrl, radius: 27),
              ),
            ),
          ),
          if (showFollow)
            Positioned(
              bottom: 0,
              child: Semantics(
                button: true,
                label: 'Takip et',
                child: GestureDetector(
                  onTap: onFollow,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    this.color = Colors.white,
    this.mirror = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color color;
  final bool mirror;

  static const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 8)];

  @override
  Widget build(BuildContext context) {
    Widget glyph = Icon(icon, color: color, size: 42, shadows: _shadow);
    if (mirror) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }
    return Semantics(
      button: true,
      label: '$semanticLabel, $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              glyph,
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  shadows: _shadow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftButton extends StatelessWidget {
  const _GiftButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hediye gönder',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFC928), Color(0xFFB832FF)],
                ).createShader(b),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Hediye',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  shadows: _ActionButton._shadow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicDisc extends StatefulWidget {
  const _MusicDisc({required this.coverUrl, required this.onTap});

  final String? coverUrl;
  final VoidCallback onTap;

  @override
  State<_MusicDisc> createState() => _MusicDiscState();
}

class _MusicDiscState extends State<_MusicDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Müzik',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A1745),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: RotationTransition(
            turns: _spin,
            child: UserAvatar(url: widget.coverUrl, radius: 24),
          ),
        ),
      ),
    );
  }
}

class ShortVideoInfoOverlay extends StatelessWidget {
  static const _textShadow = [Shadow(color: Color(0x99000000), blurRadius: 6)];

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
        GestureDetector(
          onTap: onAuthorTap,
          child: Row(
            children: [
              if (author != null) ...[
                Flexible(
                  child: Text(
                    '@${author.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      shadows: _textShadow,
                    ),
                  ),
                ),
                if (author.isVerified) ...[
                  const SizedBox(width: 6),
                  const ShortsVerifiedBadge(size: 18),
                ],
                const SizedBox(width: 8),
              ],
              Text(
                '· ${formatShortCount(video.viewsCount)} izlenme',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  shadows: _textShadow,
                ),
              ),
            ],
          ),
        ),
        if (desc != null && desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
              shadows: _textShadow,
            ),
          ),
        ],
        if (video.hashtags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 2,
            children: [
              for (final tag in video.hashtags.take(6))
                GestureDetector(
                  onTap: () => context.push(
                    '/shorts/hashtag/${Uri.encodeComponent(tag)}',
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Color(0xFFA78BFA),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      shadows: _textShadow,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
