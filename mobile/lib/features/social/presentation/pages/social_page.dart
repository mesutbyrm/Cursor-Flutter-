import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../providers/social_providers.dart';

class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      ref.read(socialNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialNotifierProvider);

    return DiscoverTabScrollPage(
      title: 'Abonelikler',
      subtitle: 'Topluluk paylaşımları ve ünlü içerikler',
      scrollController: _scroll,
      onRefresh: () => ref.read(socialNotifierProvider.notifier).refresh(),
      actions: [
        DiscoverIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Yenile',
          onPressed: () => ref.read(socialNotifierProvider.notifier).refresh(),
        ),
      ],
      slivers: [
        social.when(
          loading: () => const SliverFillRemaining(
            child: DiscoverAccentLoader(),
          ),
          error: (e, _) => SliverFillRemaining(
            child: DiscoverEmptyState(
              icon: Icons.cloud_off_rounded,
              message: ApiException.userMessage(e),
              actionLabel: 'Tekrar dene',
              action: () =>
                  ref.read(socialNotifierProvider.notifier).refresh(),
            ),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return SliverFillRemaining(
                child: DiscoverEmptyState(
                  icon: Icons.forum_outlined,
                  message: Env.useNextAuth
                      ? 'Henüz paylaşım yok.\nGiriş yaptıysanız canlifal.com ile aynı oturumu kullanın.'
                      : 'Henüz paylaşım yok.',
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DiscoverGlassCard(
                        borderColor:
                            AppDesign.accentCyan.withValues(alpha: 0.35),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    AppDesign.accentCyan.withValues(alpha: 0.25),
                                    AppDesign.accentPurple.withValues(alpha: 0.2),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: AppDesign.accentCyan,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Premium ve takip ettiğin hesapların akışı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppDesign.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final post = posts[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _SocialPostCard(post: post),
                  );
                },
                childCount: posts.length + 1,
              ),
            ),
            );
          },
        ),
      ],
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    return DiscoverGlassCard(
      onTap: () => context.push('/user/${post.author.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppDesign.heroGradient,
                ),
                child: UserAvatar(url: post.author.avatarUrl, radius: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.author.display,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppDesign.accentPurple.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                    if (post.createdAt != null)
                      Text(
                        _formatTime(post.createdAt!),
                        style: const TextStyle(
                          color: AppDesign.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.caption ?? '',
            style: const TextStyle(
              height: 1.4,
              fontSize: 14.5,
              color: AppDesign.textPrimary,
            ),
          ),
          if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.mediaUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF1E1E2E),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppDesign.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.favorite_border_rounded,
                label: '${post.likesCount}',
              ),
              const SizedBox(width: 16),
              _StatChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.commentsCount}',
              ),
              if (post.viewCount > 0) ...[
                const SizedBox(width: 16),
                _StatChip(
                  icon: Icons.visibility_outlined,
                  label: '${post.viewCount}',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Az önce';
    if (d.inHours < 1) return '${d.inMinutes} dk';
    if (d.inHours < 24) return '${d.inHours} sa';
    if (d.inDays < 7) return '${d.inDays} gün';
    return '${t.day}.${t.month}.${t.year}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppDesign.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppDesign.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
