import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
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
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _fortuneLabel(String? slug) {
    if (slug == null || slug.trim().isEmpty) return '';
    return slug.replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sosyal',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              'canlifal.com paylaşımları',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () =>
                ref.read(socialNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: social.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ApiException.userMessage(e),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(socialNotifierProvider.notifier).refresh(),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forum_outlined,
                        size: 56, color: AppTheme.muted),
                    const SizedBox(height: 16),
                    Text(
                      Env.useNextAuth
                          ? 'Henüz sosyal paylaşım yok veya liste boş döndü.\n'
                              'Ağ bağlantınızı kontrol edin; giriş yaptıysanız canlifal.com ile aynı oturumu kullanırsınız.'
                          : 'Henüz paylaşım yok.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () =>
                ref.read(socialNotifierProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) {
                  ref.read(socialNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  12,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                  12,
                  100,
                ),
                itemCount: posts.length,
                itemBuilder: (ctx, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SocialPostCard(
                      post: posts[i],
                      fortuneLabel: _fortuneLabel,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({
    required this.post,
    required this.fortuneLabel,
  });

  final PostEntity post;
  final String Function(String?) fortuneLabel;

  @override
  Widget build(BuildContext context) {
    final ft = fortuneLabel(post.fortuneType);
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/user/${post.author.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(url: post.author.avatarUrl, radius: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.display,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (post.createdAt != null)
                          Text(
                            _formatTime(post.createdAt!),
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (ft.isNotEmpty)
                    Chip(
                      label: Text(
                        ft,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              if (post.isAutoShare) ...[
                const SizedBox(height: 6),
                Text(
                  'Otomatik paylaşıldı',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accent.withValues(alpha: 0.9),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                post.caption ?? '',
                style: const TextStyle(
                  height: 1.35,
                  fontSize: 14,
                ),
              ),
              if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.surfaceElevated,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppTheme.muted),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.favorite_border,
                      size: 18, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}',
                      style: const TextStyle(color: AppTheme.muted)),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline,
                      size: 18, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}',
                      style: const TextStyle(color: AppTheme.muted)),
                  if (post.viewCount > 0) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.visibility_outlined,
                        size: 18, color: AppTheme.muted),
                    const SizedBox(width: 4),
                    Text('${post.viewCount}',
                        style: const TextStyle(color: AppTheme.muted)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final now = DateTime.now();
    final d = now.difference(t);
    if (d.inMinutes < 1) return 'Az önce';
    if (d.inHours < 1) return '${d.inMinutes} dk';
    if (d.inHours < 24) return '${d.inHours} sa';
    if (d.inDays < 7) return '${d.inDays} gün';
    return '${t.day}.${t.month}.${t.year}';
  }
}
