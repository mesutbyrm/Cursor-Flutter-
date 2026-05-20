import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_background.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../../core/widgets/shell_app_bar_widgets.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
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

  double get _topInset => MediaQuery.paddingOf(context).top + kToolbarHeight + 6;

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leadingWidth: 48,
        leading: const ShellProfileLeading(),
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [
              AppTheme.accentGold,
              AppTheme.accent,
            ],
          ).createShader(b),
          child: const Text(
            'Sosyal',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          const ShellNotificationsButton(),
          const ShellCoinBalanceAction(),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () =>
                ref.read(socialNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CosmicBackground(),
          social.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 52,
                      color: AppTheme.muted.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      ApiException.userMessage(e),
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.35),
                    ),
                    const SizedBox(height: 16),
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
                    child: GlowPanel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 52,
                            color: AppTheme.muted.withValues(alpha: 0.85),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            Env.useNextAuth
                                ? 'Henüz sosyal paylaşım yok veya liste boş döndü.\n'
                                    'Ağ bağlantınızı kontrol edin; giriş yaptıysanız canlifal.com ile aynı oturumu kullanırsınız.'
                                : 'Henüz paylaşım yok.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.muted.withValues(alpha: 0.98),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(14, _topInset, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GlowPanel(
                                borderRadius: 20,
                                padding: const EdgeInsets.fromLTRB(
                                    14, 14, 14, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: AppTheme.accentSecondary
                                            .withValues(alpha: 0.12),
                                      ),
                                      child: Icon(
                                        Icons.public_rounded,
                                        color: AppTheme.accentSecondary
                                            .withValues(alpha: 0.95),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Topluluk akışı',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'canlifal.com ile aynı paylaşımlar',
                                            style: TextStyle(
                                              color: AppTheme.muted,
                                              fontSize: 12,
                                              height: 1.25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SocialBranchQuickActions(),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _SocialPostCard(
                                  post: posts[i],
                                  fortuneLabel: _fortuneLabel,
                                ),
                              );
                            },
                            childCount: posts.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/user/${post.author.id}'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.surface.withValues(alpha: 0.92),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(url: post.author.avatarUrl, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.display,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (post.createdAt != null)
                            Text(
                              _formatTime(post.createdAt!),
                              style: TextStyle(
                                color: AppTheme.muted.withValues(alpha: 0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (ft.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accent.withValues(alpha: 0.25),
                              AppTheme.accentSecondary.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                        child: Text(
                          ft,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (post.isAutoShare) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Otomatik paylaşıldı',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent.withValues(alpha: 0.95),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  post.caption ?? '',
                  style: const TextStyle(
                    height: 1.4,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 19,
                        color: AppTheme.muted.withValues(alpha: 0.9)),
                    const SizedBox(width: 5),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        color: AppTheme.muted.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 19,
                        color: AppTheme.muted.withValues(alpha: 0.9)),
                    const SizedBox(width: 5),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(
                        color: AppTheme.muted.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (post.viewCount > 0) ...[
                      const SizedBox(width: 18),
                      Icon(Icons.visibility_outlined,
                          size: 19,
                          color: AppTheme.muted.withValues(alpha: 0.9)),
                      const SizedBox(width: 5),
                      Text(
                        '${post.viewCount}',
                        style: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
