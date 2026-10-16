import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/providers/auth_selectors.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import '../../../../fortune/presentation/data/fortune_catalog.dart';
import '../../../../messages/presentation/providers/messages_providers.dart';
import '../../../../moderation/domain/entities/report_target.dart';
import '../../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../../shorts/presentation/utils/short_video_player_util.dart';
import '../../providers/social_providers.dart';
import '../../utils/social_caption_link_parser.dart';
import '../../utils/social_post_detail_route.dart';
import '../../utils/social_user_profile_route.dart';
import '../instagram/double_tap_heart.dart';
import '../instagram/social_post_comments_sheet.dart';
import '../instagram/social_post_video_player.dart' show socialPostLooksLikeVideo;
import 'social_fortune_page.dart';

/// GirLive Sosyal — tek paylaşım, tam ekran (TikTok tarzı).
/// Video, görsel ve yazı paylaşımları ekrana sığdırılır; sağda eylem rayı,
/// solda yazar ve açıklama.
class SocialReelItem extends ConsumerStatefulWidget {
  const SocialReelItem({
    super.key,
    required this.post,
    required this.active,
    required this.topInset,
    required this.bottomInset,
    required this.onChanged,
    required this.onRemoved,
  });

  final PostEntity post;

  /// Ekranda görünen sayfa mı (video yalnızca bu sırada oynar).
  final bool active;
  final double topInset;
  final double bottomInset;
  final ValueChanged<PostEntity> onChanged;
  final VoidCallback onRemoved;

  @override
  ConsumerState<SocialReelItem> createState() => _SocialReelItemState();
}

class _SocialReelItemState extends ConsumerState<SocialReelItem> {
  static final Set<String> _viewed = <String>{};

  late bool _liked;
  late int _likes;
  var _heartToken = 0;
  var _captionOpen = false;

  VideoPlayerController? _video;
  var _videoLoading = false;
  var _videoError = false;
  var _userPaused = false;

  PostEntity get post => widget.post;

  bool get _hasMedia => (post.mediaUrl ?? '').trim().isNotEmpty;

  bool get _isVideo =>
      _hasMedia &&
      socialPostLooksLikeVideo(postType: post.postType, mediaUrl: post.mediaUrl);

  String get _text {
    final body = post.isFortunePost ? post.displayFortuneBody : post.caption;
    return (body ?? '').trim();
  }

  @override
  void initState() {
    super.initState();
    _liked = post.isLiked;
    _likes = post.likesCount;
    _onActiveChanged();
  }

  @override
  void didUpdateWidget(covariant SocialReelItem old) {
    super.didUpdateWidget(old);
    if (old.post.id != post.id) {
      _liked = post.isLiked;
      _likes = post.likesCount;
      _disposeVideo();
    }
    if (old.active != widget.active || old.post.id != post.id) {
      _onActiveChanged();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _onActiveChanged() {
    if (widget.active) {
      _registerView();
      if (_isVideo) {
        _userPaused = false;
        if (_video == null) {
          unawaited(_initVideo());
        } else {
          unawaited(_video!.play());
        }
      }
    } else {
      // Ekrandan çıkan video durur ve bellek boşaltılır.
      _disposeVideo();
    }
  }

  void _registerView() {
    final id = post.id;
    if (id.isEmpty || !_viewed.add(id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(socialRemoteProvider).registerPostView(id));
    });
  }

  Future<void> _initVideo() async {
    if (_videoLoading) return;
    setState(() {
      _videoLoading = true;
      _videoError = false;
    });
    try {
      final c = await createShortVideoController(
        url: post.mediaUrl!.trim(),
        videoId: post.id,
        dio: ref.read(dioProvider),
      );
      if (!mounted || !widget.active) {
        await c.dispose();
        if (mounted) setState(() => _videoLoading = false);
        return;
      }
      await c.setLooping(true);
      await c.setVolume(1);
      await c.play();
      setState(() {
        _video = c;
        _videoLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _videoLoading = false;
          _videoError = true;
        });
      }
    }
  }

  void _disposeVideo() {
    final c = _video;
    _video = null;
    if (c != null) unawaited(c.dispose());
  }

  void _togglePause() {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      _userPaused = !_userPaused;
      _userPaused ? c.pause() : c.play();
    });
  }

  Future<void> _toggleLike() async {
    if (ref.read(currentUserIdProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beğenmek için giriş yapın')),
      );
      return;
    }
    final prevLiked = _liked;
    final prevLikes = _likes;
    setState(() {
      _liked = !_liked;
      _likes = (_likes + (_liked ? 1 : -1)).clamp(0, 1 << 31);
    });
    try {
      final r = await ref.read(socialRepositoryProvider).toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        _liked = r.liked;
        if (r.likesCount > 0) _likes = r.likesCount;
      });
      widget.onChanged(post.copyWith(
        isLiked: _liked,
        likedByMe: _liked,
        likesCount: _likes,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = prevLiked;
        _likes = prevLikes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  void _doubleTapLike() {
    setState(() => _heartToken++);
    if (!_liked) unawaited(_toggleLike());
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: buildSocialPostShareText(
          postId: post.id,
          caption: _text,
          siteOrigin: Env.siteOrigin,
        ),
      ),
    );
    widget.onChanged(post.copyWith(shareCount: post.shareCount + 1));
    // Sahibine «X gönderini paylaştı» bildirimi (sunucu).
    unawaited(
      ref
          .read(dioProvider)
          .safePost<dynamic>('/api/social/posts/${post.id}/share')
          .then((_) {}, onError: (_) {}),
    );
  }

  Future<void> _openComments() async {
    await SocialPostCommentsSheet.show(
      context,
      postId: post.id,
      initialCount: post.commentsCount,
      onCountDelta: (d) {
        if (!mounted) return;
        final p = widget.post;
        widget.onChanged(
          p.copyWith(commentsCount: (p.commentsCount + d).clamp(0, 1 << 31)),
        );
      },
    );
  }

  void _openProfile() {
    context.push(buildSocialUserProfileRoute(post.author.id), extra: post.id);
  }

  Future<void> _openMenu() async {
    final myId = ref.read(currentUserIdProvider);
    final mine = myId != null && myId == post.author.id;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Gönderiyi aç'),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            if (!mine) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Şikayet et'),
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('Kullanıcıyı engelle'),
                onTap: () => Navigator.pop(ctx, 'block'),
              ),
            ],
            if (mine)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Gönderiyi sil',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'open':
        context.push(buildSocialPostDetailRoute(post.id));
      case 'report':
        openReportFlow(
          context,
          ReportTarget(
            type: ReportTargetType.post,
            targetId: post.id,
            ownerUserId: post.author.id,
            displayTitle: 'Gönderi',
          ),
        );
      case 'block':
        try {
          await ref.read(messagesRemoteProvider).blockUser(post.author.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${post.author.display} engellendi')),
          );
          widget.onRemoved();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
      case 'delete':
        try {
          await ref.read(socialRepositoryProvider).deletePost(post.id);
          ref.read(socialNotifierProvider.notifier).removePost(post.id);
          if (!mounted) return;
          widget.onRemoved();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gönderi silindi')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silinemedi: ${ApiException.userMessage(e)}')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isVideo ? _togglePause : null,
            onDoubleTap: _doubleTapLike,
            child: _content(),
          ),
          // Alt/üst okunabilirlik gölgesi.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.16, 0.62, 1],
                  colors: [
                    Color(0x8C000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xB3000000),
                  ],
                ),
              ),
            ),
          ),
          if (_isVideo && _userPaused)
            const IgnorePointer(
              child: Center(
                child: Icon(Icons.play_arrow_rounded,
                    size: 84, color: Color(0xCCFFFFFF)),
              ),
            ),
          IgnorePointer(child: Center(child: DoubleTapHeart(token: _heartToken))),
          Positioned(
            right: 8,
            bottom: widget.bottomInset + 12,
            child: _ActionRail(
              post: post,
              liked: _liked,
              likes: _likes,
              onAvatar: _openProfile,
              onLike: _toggleLike,
              onComment: _openComments,
              onShare: _share,
              onMore: _openMenu,
            ),
          ),
          Positioned(
            left: 14,
            right: 84,
            bottom: widget.bottomInset + 14,
            child: _InfoBlock(
              post: post,
              text: _hasMedia && !post.isFortunePost ? _text : '',
              expanded: _captionOpen,
              onToggle: () => setState(() => _captionOpen = !_captionOpen),
              onAuthor: _openProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_isVideo) return _videoView();
    // Fal paylaşımı: falın görseli arka planda, yorumun tamamı okunabilir.
    if (post.isFortunePost) {
      return SocialFortunePage(
        post: post,
        text: _text,
        imageUrl: _hasMedia ? post.mediaUrl!.trim() : null,
        topInset: widget.topInset,
        bottomInset: widget.bottomInset,
      );
    }
    if (_hasMedia) return _ImageFill(url: post.mediaUrl!.trim());
    return _TextPage(
      post: post,
      text: _text,
      topInset: widget.topInset,
      bottomInset: widget.bottomInset,
    );
  }

  Widget _videoView() {
    final c = _video;
    if (c != null && c.value.isInitialized) {
      final size = c.value.size;
      final ar = size.height == 0 ? 9 / 16 : size.width / size.height;
      // Dikey video ekranı doldurur; yatay/kare video kırpılmadan sığdırılır.
      final fit = ar < 0.75 ? BoxFit.cover : BoxFit.contain;
      return FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(c),
        ),
      );
    }
    return Center(
      child: _videoError
          ? const Icon(Icons.videocam_off_outlined,
              color: Colors.white38, size: 48)
          : const CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white54),
    );
  }
}

/// Görsel: arka planda bulanık kopya (tam ekran), önde kırpılmadan sığdırılmış.
class _ImageFill extends StatelessWidget {
  const _ImageFill({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Opacity(
            opacity: 0.55,
            child: CanlifalNetworkImage(url: url, fit: BoxFit.cover),
          ),
        ),
        CanlifalNetworkImage.full(
          url: url,
          fit: BoxFit.contain,
          errorWidget: const Center(
            child: Icon(Icons.broken_image_outlined,
                color: Colors.white38, size: 48),
          ),
        ),
      ],
    );
  }
}

/// Yazı paylaşımı: renkli zemin üzerinde ekrana sığan büyük metin.
class _TextPage extends StatelessWidget {
  const _TextPage({
    required this.post,
    required this.text,
    required this.topInset,
    required this.bottomInset,
  });

  final PostEntity post;
  final String text;
  final double topInset;
  final double bottomInset;

  static const _palettes = <List<Color>>[
    [Color(0xFF25F4EE), Color(0xFF0B0B12), Color(0xFFFE2C55)],
    [Color(0xFF7C3AED), Color(0xFF1E1B4B), Color(0xFFDB2777)],
    [Color(0xFF0EA5E9), Color(0xFF0F172A), Color(0xFF22C55E)],
    [Color(0xFFF59E0B), Color(0xFF1C1917), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF111827), Color(0xFF8B5CF6)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[post.id.hashCode.abs() % _palettes.length];
    final len = text.characters.length;
    final size = len <= 60
        ? 32.0
        : len <= 160
            ? 25.0
            : len <= 400
                ? 20.0
                : 17.0;
    final fortune = post.isFortunePost
        ? FortuneCatalog.bySlug(post.fortuneSlug ?? post.fortuneType ?? '')
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0].withValues(alpha: 0.55),
            colors[1],
            colors[2].withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topInset + 56, 84, bottomInset + 96),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (post.isFortunePost)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      '🔮 ${fortune?.title ?? 'Fal'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  text.isEmpty ? '…' : text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
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

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.post,
    required this.liked,
    required this.likes,
    required this.onAvatar,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onMore,
  });

  final PostEntity post;
  final bool liked;
  final int likes;
  final VoidCallback onAvatar;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onAvatar,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: UserAvatar(url: post.author.avatarUrl, radius: 22),
          ),
        ),
        const SizedBox(height: 18),
        _RailButton(
          icon: Icons.favorite_rounded,
          color: liked ? const Color(0xFFFE2C55) : Colors.white,
          label: _count(likes),
          onTap: onLike,
        ),
        _RailButton(
          icon: Icons.chat_bubble_rounded,
          label: _count(post.commentsCount),
          onTap: onComment,
        ),
        _RailButton(
          icon: Icons.reply_rounded,
          mirror: true,
          label: _count(post.shareCount),
          onTap: onShare,
        ),
        _RailButton(
          icon: Icons.more_horiz_rounded,
          label: '',
          onTap: onMore,
        ),
      ],
    );
  }

  static String _count(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}B';
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)}';
    }
    return '$n';
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.mirror = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    Widget ic = Icon(
      icon,
      size: 36,
      color: color,
      shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
    );
    if (mirror) {
      ic = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1, 1, 1),
        child: ic,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            ic,
            if (label.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.post,
    required this.text,
    required this.expanded,
    required this.onToggle,
    required this.onAuthor,
  });

  final PostEntity post;
  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAuthor;

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Colors.black87, blurRadius: 8)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onAuthor,
          child: Text(
            post.author.display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              shadows: shadow,
            ),
          ),
        ),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: expanded
                    ? MediaQuery.sizeOf(context).height * 0.35
                    : double.infinity,
              ),
              child: SingleChildScrollView(
                physics: expanded
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Text.rich(
                  TextSpan(
                    text: text,
                    children: [
                      if (!expanded && text.length > 90)
                        const TextSpan(
                          text: '  daha fazla',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                  maxLines: expanded ? null : 2,
                  overflow:
                      expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.3,
                    shadows: shadow,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
