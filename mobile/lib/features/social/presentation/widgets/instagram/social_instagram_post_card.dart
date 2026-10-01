import 'package:canlifal_social/core/design_system/cds_button.dart';
import 'package:canlifal_social/core/motion/canlifal_motion_widgets.dart';
import 'package:canlifal_social/core/design_system/cds_dialog.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/canlifal_brand_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/shorts/presentation/widgets/shorts_profile_content.dart';
import 'package:canlifal_social/features/vip_gold/presentation/widgets/vip_badge.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../../../core/providers/auth_selectors.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import '../../../../../core/config/env.dart';
import '../../../../../core/network/api_exception.dart';
import '../../utils/social_caption_link_parser.dart';
import '../../utils/social_post_detail_route.dart';
import '../../utils/social_user_profile_route.dart';
import '../../providers/social_providers.dart';
import 'social_fortune_scene_card.dart';
import 'social_post_caption.dart';
import 'social_post_comments_sheet.dart';
import 'social_post_video_player.dart';
import 'double_tap_heart.dart';

/// CanlıFal Sosyal akış kartı — fal rozeti, otomatik paylaşım, etkileşim.
class SocialInstagramPostCard extends ConsumerStatefulWidget {
  const SocialInstagramPostCard({
    super.key,
    required this.post,
    this.openProfileOnTap = true,
    this.onDeleted,
  });

  final PostEntity post;
  final bool openProfileOnTap;
  final VoidCallback? onDeleted;

  @override
  ConsumerState<SocialInstagramPostCard> createState() =>
      _SocialInstagramPostCardState();
}

class _SocialInstagramPostCardState
    extends ConsumerState<SocialInstagramPostCard> {
  late bool _liked;
  late int _likeCount;
  var _likeBurst = 0;
  var _doubleTapHearts = 0;

  @override
  void initState() {
    super.initState();
    _syncFromPost(widget.post);
    final postId = widget.post.id;
    if (postId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(socialNotifierProvider.notifier).registerView(postId);
        ref.read(socialRemoteProvider).registerPostView(postId);
      });
    }
  }

  @override
  void didUpdateWidget(covariant SocialInstagramPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likesCount != widget.post.likesCount ||
        oldWidget.post.likedByMe != widget.post.likedByMe) {
      _syncFromPost(widget.post);
    }
  }

  void _syncFromPost(PostEntity p) {
    _liked = p.likedByMe;
    _likeCount = p.likesCount;
  }

  PostEntity get post => widget.post;

  bool get _isFortunePost => post.isFortunePost;

  String? get _bodyText {
    if (_isFortunePost) return post.displayFortuneBody;
    return post.caption?.trim();
  }

  bool get _hasMedia =>
      post.mediaUrl != null && post.mediaUrl!.trim().isNotEmpty;

  void _openAuthorTimeline(BuildContext context) {
    context.push(buildSocialUserProfileRoute(post.author.id), extra: post.id);
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserIdProvider);
    final isMine = myId != null && myId == post.author.id;
    final likeCount = _likeCount;

    final dark = context.isDarkTheme;
    final mediaIsImage =
        _hasMedia &&
        !socialPostLooksLikeVideo(
          postType: post.postType,
          mediaUrl: post.mediaUrl!.trim(),
        );
    // Fal paylaşımı: türe uygun görselin üzerine metin (otomatik paylaşımda
    // sunucunun genel görseli yerine, medya yoksa da).
    final useScene =
        _isFortunePost &&
        (_bodyText?.isNotEmpty ?? false) &&
        (!_hasMedia || post.isAutoShare);
    final headerOnMedia = mediaIsImage && (_bodyText?.isEmpty ?? true);
    Widget header({bool onMedia = false}) => _PostHeader(
      post: post,
      isMine: isMine,
      onMedia: onMedia,
      onProfile: () => _openAuthorTimeline(context),
      onShare: () => _sharePost(context),
      onDelete: isMine ? () => _deletePost(context) : null,
    );
    Widget actions({bool onMedia = false}) =>
        _buildActions(context, likeCount, onMedia: onMedia);
    // Listede blur yok: tek düz yüzey + ince kenar (kaydırmada ucuz).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : context.colors.outlineVariant,
          ),
          boxShadow: dark ? null : context.colors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!headerOnMedia) header(),
              GestureDetector(
                onTap: widget.openProfileOnTap
                    ? () => _openAuthorTimeline(context)
                    : null,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (useScene)
                      SocialFortuneSceneCard(
                        fortuneType: post.fortuneType ?? post.fortuneSlug,
                        typeLabel:
                            _PostHeader._fortuneTypeLabel(
                              post.fortuneType ?? post.fortuneSlug,
                              post.postType,
                            ) ??
                            'Fal',
                        body: _bodyText!,
                        onTap: () => _openPostDetail(context),
                        onDoubleTap: _likeFromDoubleTap,
                        bottomOverlay: actions(onMedia: true),
                      ),
                    if (!useScene &&
                        (_bodyText?.isNotEmpty ?? false) &&
                        _hasMedia)
                      SocialPostCaption(
                        post: post,
                        inlineBodyOnly: true,
                        bodyText: _bodyText,
                      ),
                    if (!useScene &&
                        !_hasMedia &&
                        (_bodyText?.isNotEmpty ?? false))
                      GestureDetector(
                        onTap: () => _openPostDetail(context),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: dark
                                    ? const [
                                        Color(0xFF241A3D),
                                        Color(0xFF141419),
                                      ]
                                    : const [
                                        Color(0xFFF3EEFF),
                                        Color(0xFFEAF7F5),
                                      ],
                              ),
                              border: Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: dark ? 0.30 : 0.18,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SocialPostTextPreview(text: _bodyText!),
                            ),
                          ),
                        ),
                      ),
                    if (!useScene && _hasMedia)
                      _PostMediaBlock(
                        post: post,
                        onFortuneTap: () => _openFortune(context),
                        onTap: () => _openPostDetail(context),
                        onDoubleTap: _likeFromDoubleTap,
                        heartToken: _doubleTapHearts,
                        topOverlay: headerOnMedia
                            ? header(onMedia: true)
                            : null,
                        bottomOverlay: mediaIsImage
                            ? actions(onMedia: true)
                            : null,
                      ),
                  ],
                ),
              ),
              if (!mediaIsImage && !useScene) actions(),
              if (_isFortunePost && post.fortuneCount > 0)
                _CoViewersBar(
                  count: post.fortuneCount,
                  onTap: () => _openPostDetail(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    int likeCount, {
    required bool onMedia,
  }) {
    final fg = onMedia ? Colors.white : null;
    final row = Row(
      children: [
        _LikeActionRow(
          liked: _liked,
          burstToken: _likeBurst,
          count: likeCount,
          onTap: _toggleLike,
          foreground: fg,
        ),
        _ActionWithCount(
          icon: Icons.chat_bubble_outline_rounded,
          semanticLabel: 'Yorumlar',
          count: post.commentsCount,
          onTap: () => _openComments(context),
          foreground: fg,
        ),
        _ActionWithCount(
          icon: Icons.repeat_rounded,
          semanticLabel: 'Paylaşım sayısı',
          count: post.shareCount,
          onTap: () => _sharePost(context),
          foreground: fg,
        ),
        _ActionWithCount(
          icon: Icons.visibility_outlined,
          semanticLabel: 'Görüntülenme, detayı aç',
          count: post.displayViewCount,
          onTap: () => _openPostDetail(context),
          foreground: fg,
        ),
        const Spacer(),
        if (_isFortunePost) ...[
          _TextAction(
            label: 'Kart',
            icon: Icons.palette_outlined,
            onTap: () => _openFortune(context),
          ),
          const SizedBox(width: 10),
        ],
        _TextAction(
          label: 'Paylaş',
          icon: Icons.send_outlined,
          onTap: () => _sharePost(context),
        ),
      ],
    );
    if (!onMedia) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 10, 2),
        child: row,
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xCC0B0616)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 28, 8, 4),
        child: row,
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final ok = await CdsDialog.confirm(
      context,
      title: 'Gönderiyi sil',
      message: 'Bu paylaşımı kaldırmak istediğinize emin misiniz?',
      cancelLabel: 'Vazgeç',
      confirmLabel: 'Sil',
      confirmVariant: CdsButtonVariant.danger,
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(socialRepositoryProvider).deletePost(post.id);
      ref.read(socialNotifierProvider.notifier).removePost(post.id);
      widget.onDeleted?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gönderi silindi')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Silinemedi: $e')));
      }
    }
  }

  void _openFortune(BuildContext context) {
    final slug = post.fortuneType;
    if (slug != null && slug.isNotEmpty) {
      context.push('/fortune/$slug');
    } else {
      context.push('/fortune');
    }
  }

  /// Instagram davranışı: çift dokunuş yalnızca beğenir, beğeniyi geri almaz.
  void _likeFromDoubleTap() {
    setState(() => _doubleTapHearts++);
    if (!_liked) _toggleLike();
  }

  Future<void> _toggleLike() async {
    final myId = ref.read(currentUserIdProvider);
    if (myId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beğenmek için giriş yapın')),
        );
      }
      return;
    }
    final prevLiked = _liked;
    final prevCount = _likeCount;
    setState(() {
      final nextLiked = !_liked;
      _liked = nextLiked;
      _likeCount += nextLiked ? 1 : -1;
      if (_likeCount < 0) _likeCount = 0;
      if (nextLiked) _likeBurst++;
    });
    try {
      final r = await ref.read(socialRepositoryProvider).toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        _liked = r.liked;
        _likeCount = r.likesCount > 0 ? r.likesCount : _likeCount;
      });
      ref
          .read(socialNotifierProvider.notifier)
          .reconcileLike(post.id, liked: r.liked, likesCount: _likeCount);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = prevLiked;
        _likeCount = prevCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
    }
  }

  void _openPostDetail(BuildContext context) {
    if (post.id.isEmpty) return;
    context.push(buildSocialPostDetailRoute(post.id));
  }

  void _openComments(BuildContext context) {
    SocialPostCommentsSheet.show(
      context,
      postId: post.id,
      initialCount: post.commentsCount,
    );
  }

  Future<void> _sharePost(BuildContext context) async {
    final text = buildSocialPostShareText(
      postId: post.id,
      caption: _bodyText ?? post.caption,
      siteOrigin: Env.siteOrigin,
    );
    await SharePlus.instance.share(ShareParams(text: text));
    if (post.id.isNotEmpty) {
      ref.read(socialNotifierProvider.notifier).bumpShareCount(post.id);
    }
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.isMine,
    required this.onProfile,
    required this.onShare,
    this.onDelete,
    this.onMedia = false,
  });

  final PostEntity post;
  final bool isMine;
  final bool onMedia;
  final VoidCallback onProfile;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final timeLabel = post.createdAt != null
        ? _formatTimeShort(post.createdAt!)
        : null;
    final fortuneLabel = _fortuneTypeLabel(post.fortuneType, post.postType);
    final nameColor = onMedia ? Colors.white : null;
    final mutedColor = onMedia
        ? Colors.white.withValues(alpha: 0.8)
        : context.colors.onSurfaceMuted.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(url: post.author.avatarUrl, radius: 20),
                      SizedBox(width: 10),
                      Expanded(
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: nameColor,
                                    ),
                                  ),
                                ),
                                if (post.author.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const ShortsVerifiedBadge(size: 14),
                                ],
                                if (shouldShowSocialMembershipBadge(
                                  post.author.role,
                                )) ...[
                                  const SizedBox(width: 4),
                                  VipBadge(
                                    tier: resolveProfileMembership(
                                      rawMembership: post.author.role,
                                    ).tier,
                                    compact: true,
                                  ),
                                ],
                                if (timeLabel != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '· $timeLabel',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (fortuneLabel != null) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _fortuneEmoji(post.fortuneType),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    fortuneLabel,
                                    style: TextStyle(
                                      color: _accentText(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<_PostMenuAction>(
            tooltip: 'Gönderi seçenekleri',
            icon: Icon(
              Icons.more_horiz_rounded,
              color: onMedia ? Colors.white : context.colors.onSurfaceVariant,
            ),
            onSelected: (action) => switch (action) {
              _PostMenuAction.profile => onProfile(),
              _PostMenuAction.share => onShare(),
              _PostMenuAction.delete => onDelete?.call(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _PostMenuAction.profile,
                child: ListTile(
                  leading: Icon(Icons.person_outline_rounded),
                  title: Text('Profili gör'),
                ),
              ),
              const PopupMenuItem(
                value: _PostMenuAction.share,
                child: ListTile(
                  leading: Icon(Icons.ios_share_rounded),
                  title: Text('Paylaş'),
                ),
              ),
              if (onDelete != null)
                PopupMenuItem(
                  value: _PostMenuAction.delete,
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppThemeColors.liveRed,
                    ),
                    title: Text(
                      'Sil',
                      style: TextStyle(color: AppThemeColors.liveRed),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String? _fortuneTypeLabel(String? type, String? postType) {
    if (type == null || type.isEmpty) {
      return postType == 'fortune' ? 'Fal' : null;
    }
    return switch (type) {
      'el-fali' || 'palm' => 'El Falı',
      'kahve-fali' || 'coffee' => 'Kahve Falı',
      'tarot' || 'gunluk-tarot' => 'Tarot',
      'yildiz-haritasi' || 'astroloji' => 'Yıldız Falı',
      'ask-fali' || 'love' => 'Aşk Falı',
      'ruya-tabiri' || 'ruya-yorumu' => 'Rüya Tabiri',
      'melek-kartlari' || 'angel' => 'Melek Kartları',
      'evet-hayir' || 'yesno' => 'Evet / Hayır',
      'katina' => 'Katina',
      'numeroloji' => 'Numeroloji',
      'iskambil' => 'İskambil',
      'pendul' => 'Pendül',
      'runik' => 'Runik',
      'cin-fali' => 'Cin Falı',
      _ => type.replaceAll('-', ' '),
    };
  }

  static String _fortuneEmoji(String? type) {
    return switch (type) {
      'el-fali' || 'palm' => '✋',
      'kahve-fali' => '☕',
      'tarot' => '🃏',
      'yildiz-haritasi' => '🔮',
      'ask-fali' => '💕',
      'ruya-tabiri' => '🌙',
      _ => '✨',
    };
  }

  static String _formatTimeShort(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'az önce';
    if (d.inHours < 1) return '${d.inMinutes} dk';
    if (d.inHours < 24) return '${d.inHours} sa';
    if (d.inDays < 7) return '${d.inDays} gün';
    return '${t.day}.${t.month}.${t.year}';
  }
}

enum _PostMenuAction { profile, share, delete }

class _CoViewersBar extends StatelessWidget {
  const _CoViewersBar({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9F1C);
    final textColor = context.isDarkTheme
        ? const Color(0xFFFFB84D)
        : const Color(0xFFB45309);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: orange.withValues(alpha: 0.9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, size: 22, color: orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu kullanıcı ile birlikte $count kişi bu fala baktı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: orange),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostMediaBlock extends StatelessWidget {
  const _PostMediaBlock({
    required this.post,
    required this.onFortuneTap,
    required this.onDoubleTap,
    required this.heartToken,
    this.onTap,
    this.topOverlay,
    this.bottomOverlay,
  });

  final PostEntity post;
  final Widget? topOverlay;
  final Widget? bottomOverlay;
  final VoidCallback onFortuneTap;
  final VoidCallback? onTap;
  final VoidCallback onDoubleTap;
  final int heartToken;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post.mediaUrl!.trim();
    final isVideo = socialPostLooksLikeVideo(
      postType: post.postType,
      mediaUrl: mediaUrl,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      // Video kendi dokunma kontrollerini kullanır; çift dokunuş yalnız görselde.
      child: isVideo
          ? GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: SocialPostVideoPlayer(
                videoUrl: mediaUrl,
                videoId: post.id,
              ),
            )
          : GestureDetector(
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              behavior: HitTestBehavior.opaque,
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CanlifalNetworkImage(
                      url: mediaUrl,
                      fit: BoxFit.cover,
                      placeholder: const _MysticMediaPlaceholder(),
                      errorWidget: const _MysticMediaPlaceholder(),
                    ),
                    Center(child: DoubleTapHeart(token: heartToken)),
                    if (topOverlay != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xB30B0616), Color(0x000B0616)],
                            ),
                          ),
                          child: topOverlay,
                        ),
                      ),
                    if (bottomOverlay != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: bottomOverlay!,
                      ),
                  ],
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
    return Image.asset(
      'assets/fortune/tarot.webp',
      fit: BoxFit.cover,
      cacheWidth: 720,
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF16161D)),
    );
  }
}

class _LikeActionRow extends StatelessWidget {
  const _LikeActionRow({
    required this.liked,
    required this.burstToken,
    required this.count,
    required this.onTap,
    this.foreground,
  });

  final bool liked;
  final int burstToken;
  final int count;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final color = liked
        ? AppThemeColors.accentPink
        : (foreground ?? context.colors.onSurface);
    return Semantics(
      button: true,
      toggled: liked,
      label: count > 0 ? 'Beğen, $count' : 'Beğen',
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CanlifalBurstIcon(
              burstToken: burstToken,
              icon: liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: color,
              onTap: onTap,
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: foreground ?? context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatCount(int n) => formatSocialCount(n);
}

class _ActionWithCount extends StatelessWidget {
  const _ActionWithCount({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.count = 0,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final int count;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final iconColor = foreground ?? context.colors.onSurface;

    return Semantics(
      button: true,
      label: '$semanticLabel, $count',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: iconColor),
              ...[
                SizedBox(width: 5),
                Text(
                  _formatCount(count),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: foreground ?? context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCount(int n) => formatSocialCount(n);
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _accentText(context)),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: _accentText(context),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Koyu zeminde açık mor, açık zeminde koyu mor — küçük metin okunur kalsın.
Color _accentText(BuildContext context) => context.isDarkTheme
    ? CanlifalBrandColors.violetBright
    : context.colors.primary;

/// 1.2K / 3.4M biçimi.
String formatSocialCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
