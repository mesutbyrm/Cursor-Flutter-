import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../../../core/providers/auth_selectors.dart';
import '../../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import '../../providers/social_providers.dart';
import 'social_post_caption.dart';

/// CanlıFal Sosyal akış kartı — fal rozeti, otomatik paylaşım, etkileşim.
class SocialInstagramPostCard extends ConsumerStatefulWidget {
  const SocialInstagramPostCard({super.key, required this.post});

  final PostEntity post;

  @override
  ConsumerState<SocialInstagramPostCard> createState() =>
      _SocialInstagramPostCardState();
}

class _SocialInstagramPostCardState
    extends ConsumerState<SocialInstagramPostCard> {
  var _liked = false;

  PostEntity get post => widget.post;

  bool get _isFortunePost =>
      post.postType == 'fortune' ||
      post.isAutoShare ||
      (post.fortuneType != null && post.fortuneType!.isNotEmpty);

  bool get _hasMedia =>
      post.mediaUrl != null && post.mediaUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserIdProvider);
    final isMine = myId != null && myId == post.author.id;
    final likeCount = post.likesCount + (_liked ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ProGlassCard(
        blur: 14,
        animateIn: false,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          border: Border.all(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.22),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PostHeader(
                post: post,
                isMine: isMine,
                onProfile: () => context.push('/user/${post.author.id}'),
                onDelete: isMine ? () => _deletePost(context) : null,
              ),
              if ((post.caption?.trim().isNotEmpty ?? false) && _hasMedia)
                SocialPostCaption(post: post, inlineBodyOnly: true),
              if (!_hasMedia && (post.caption?.trim().isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A1548), Color(0xFF14102A)],
                      ),
                      border: Border.all(
                        color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SocialPostTextPreview(text: post.caption!.trim()),
                    ),
                  ),
                ),
              if (post.isAutoShare || post.fortuneCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (post.isAutoShare) const _AutoShareBadge(),
                      if (post.fortuneCount > 0)
                        _CoViewersBadge(count: post.fortuneCount),
                    ],
                  ),
                ),
              if (_hasMedia)
                _PostMediaBlock(
                  post: post,
                  onFortuneTap: () => _openFortune(context),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    _ActionWithCount(
                      icon: _liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _liked ? AppThemeColors.accentPink : context.colors.onSurface,
                      count: likeCount,
                      onTap: () => setState(() => _liked = !_liked),
                    ),
                    SizedBox(width: 16),
                    _ActionWithCount(
                      icon: Icons.mode_comment_outlined,
                      count: post.commentsCount,
                      onTap: () => _showCommentsHint(context),
                    ),
                    SizedBox(width: 16),
                    _ActionWithCount(
                      icon: Icons.visibility_outlined,
                      count: post.viewCount,
                      hideZeroCount: false,
                      onTap: () {},
                    ),
                    SizedBox(width: 16),
                    _ActionIcon(
                      icon: Icons.ios_share_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paylaşım yakında')),
                        );
                      },
                    ),
                    const Spacer(),
                    if (_isFortunePost) ...[
                      _TextAction(
                        label: 'Kart',
                        icon: Icons.palette_outlined,
                        onTap: () => _openFortune(context),
                      ),
                      SizedBox(width: 12),
                      _TextAction(
                        label: 'Detay',
                        icon: Icons.open_in_new_rounded,
                        onTap: () => _openFortune(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (post.commentsCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: GestureDetector(
                    onTap: () => _showCommentsHint(context),
                    child: Text(
                      '${post.commentsCount} yorumun tümünü gör',
                      style: TextStyle(
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: Text('Gönderiyi sil'),
        content: Text('Bu paylaşımı kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(socialRepositoryProvider).deletePost(post.id);
      await ref.read(socialNotifierProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderi silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silinemedi: $e')),
        );
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

  void _showCommentsHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yorumlar yakında')),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.isMine,
    required this.onProfile,
    this.onDelete,
  });

  final PostEntity post;
  final bool isMine;
  final VoidCallback onProfile;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final timeLabel = post.createdAt != null
        ? _formatTimeShort(post.createdAt!)
        : null;
    final fortuneLabel = _fortuneTypeLabel(post.fortuneType, post.postType);

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
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (timeLabel != null) ...[
                                  SizedBox(width: 6),
                                  Text(
                                    '· $timeLabel',
                                    style: TextStyle(
                                      color: context.colors.onSurfaceMuted
                                          .withValues(alpha: 0.85),
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
                                      color: AppThemeColors.accentPurple
                                          .withValues(alpha: 0.95),
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
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 22),
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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

class _AutoShareBadge extends StatelessWidget {
  const _AutoShareBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemeColors.accentPurple.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: AppThemeColors.accentPink.withValues(alpha: 0.95),
          ),
          SizedBox(width: 5),
          Text(
            'Otomatik paylaşıldı',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoViewersBadge extends StatelessWidget {
  const _CoViewersBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF8C42).withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      child: Text(
        'Bu kullanıcı ile birlikte $count kişi bu fala baktırdı',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFFFB366).withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _PostMediaBlock extends StatelessWidget {
  const _PostMediaBlock({
    required this.post,
    required this.onFortuneTap,
  });

  final PostEntity post;
  final VoidCallback onFortuneTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: CachedNetworkImage(
          imageUrl: post.mediaUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => const _MysticMediaPlaceholder(),
          errorWidget: (_, _, _) => const _MysticMediaPlaceholder(),
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
      decoration: BoxDecoration(
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
      child: Center(
        child: Text('🔮', style: TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _ActionWithCount extends StatelessWidget {
  const _ActionWithCount({
    required this.icon,
    required this.onTap,
    this.count = 0,
    this.color,
    this.hideZeroCount = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int count;
  final Color? color;
  final bool hideZeroCount;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? context.colors.onSurface;
    final showCountLabel = !hideZeroCount || count > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: iconColor),
            if (showCountLabel) ...[
              SizedBox(width: 5),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: context.colors.onSurfaceVariant,
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

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 24, color: context.colors.onSurface),
      ),
    );
  }
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
            Icon(icon, size: 18, color: AppThemeColors.accentPurple),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppThemeColors.accentPurple.withValues(alpha: 0.95),
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
