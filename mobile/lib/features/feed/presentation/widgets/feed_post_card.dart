import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';

class FeedPostCard extends ConsumerStatefulWidget {
  const FeedPostCard({super.key, required this.post});

  final PostEntity post;

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  bool _viewSent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_viewSent) {
      _viewSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(feedNotifierProvider.notifier).registerView(widget.post.id);
        }
      });
    }
  }

  void _openComments() {
    final textController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Yorumlar · ${widget.post.commentsCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Yorumunu yaz…',
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (textController.text.trim().isEmpty) return;
                  ref.read(feedNotifierProvider.notifier).addComment(widget.post.id);
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Gönder'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(textController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppTheme.surface.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 9 / 13,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (p.mediaUrl != null && p.mediaUrl!.isNotEmpty)
                      Image.network(
                        p.mediaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surfaceElevated,
                          alignment: Alignment.center,
                          child: const Icon(Icons.play_circle_fill,
                              size: 64, color: AppTheme.muted),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E1E2E),
                              Color(0xFF0B0B0F),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.movie_filter_rounded,
                              size: 64, color: AppTheme.muted),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.push('/user/${p.author.id}'),
                                  child: Row(
                                    children: [
                                      UserAvatar(url: p.author.avatarUrl, radius: 18),
                                      const SizedBox(width: 10),
                                      Text(
                                        p.author.display,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if ((p.caption ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                p.caption!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Row(
                  children: [
                    _ActionChip(
                      icon: p.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: '${p.likesCount}',
                      color: p.isLiked ? AppTheme.accent : Colors.white,
                      onTap: () => ref
                          .read(feedNotifierProvider.notifier)
                          .toggleLike(p.id),
                    ),
                    const SizedBox(width: 6),
                    _ActionChip(
                      icon: Icons.mode_comment_outlined,
                      label: '${p.commentsCount}',
                      color: Colors.white,
                      onTap: _openComments,
                    ),
                    const SizedBox(width: 6),
                    _ActionChip(
                      icon: Icons.remove_red_eye_outlined,
                      label: '${p.viewsCount}',
                      color: Colors.white70,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
