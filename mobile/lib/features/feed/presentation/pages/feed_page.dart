import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_background.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/feed_providers.dart';
import '../widgets/feed_home_sections.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    await ref.read(feedNotifierProvider.notifier).refresh();
    ref.invalidate(liveStreamsProvider);
    ref.invalidate(voiceRoomsProvider);
    ref.invalidate(coinBalanceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final coins = ref.watch(coinBalanceProvider);
    final feed = ref.watch(feedNotifierProvider);
    final topPad = MediaQuery.paddingOf(context).top;

    final user = auth.valueOrNull;
    final userName = user?.display ?? 'Kullanıcı';
    final coinText = coins.whenOrNull(data: (c) => c) ?? 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CosmicBackground(),
          RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: _refreshHome,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels > n.metrics.maxScrollExtent - 500) {
                  ref.read(feedNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
                      child: _HomeHeader(
                        userName: userName,
                        avatarUrl: user?.avatarUrl,
                        coinBalance: coinText,
                        onNotifications: () => context.push('/notifications'),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _HeroText(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          HomeLiveStrip(),
                          SizedBox(height: 20),
                          HomeQuickActions(),
                          SizedBox(height: 20),
                          HomeChatRooms(),
                          SizedBox(height: 20),
                          HomeFortuneTarot(),
                        ],
                      ),
                    ),
                  ),
                  if (feed.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (feed.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ApiException.userMessage(feed.error!),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => ref
                                  .read(feedNotifierProvider.notifier)
                                  .refresh(),
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (feed.hasValue && feed.requireValue.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final p = feed.requireValue[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AspectRatio(
                                  aspectRatio: 9 / 14,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (p.mediaUrl != null &&
                                          p.mediaUrl!.isNotEmpty)
                                        Image.network(
                                          p.mediaUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: AppTheme.surfaceElevated,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                                Icons.play_circle_fill,
                                                size: 64,
                                                color: AppTheme.muted),
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
                                            child: Icon(
                                                Icons.movie_filter_rounded,
                                                size: 64,
                                                color: AppTheme.muted),
                                          ),
                                        ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              14, 36, 14, 14),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => context.push(
                                                        '/user/${p.author.id}'),
                                                    child: Row(
                                                      children: [
                                                        UserAvatar(
                                                          url:
                                                              p.author.avatarUrl,
                                                          radius: 18,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Text(
                                                          p.author.display,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  const Icon(
                                                      Icons.favorite_border,
                                                      color: Colors.white),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${p.likesCount}',
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                p.caption ?? '',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  height: 1.25,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: feed.requireValue.length,
                        ),
                      ),
                    )
                  else
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 120),
                      sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.avatarUrl,
    required this.coinBalance,
    required this.onNotifications,
  });

  final String userName;
  final String? avatarUrl;
  final int coinBalance;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            UserAvatar(url: avatarUrl, radius: 22),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.background, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoş geldin',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.muted.withValues(alpha: 0.9),
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.cosmicPurple.withValues(alpha: 0.4),
                AppTheme.accent.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.cosmicPurple.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond_rounded,
                  color: AppTheme.cosmicPink, size: 16),
              const SizedBox(width: 4),
              Text(
                _formatNumber(coinBalance),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onNotifications,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 22),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return n.toString();
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Canlı yayınlara',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
            children: [
              TextSpan(
                text: 'katıl, ',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.cosmicPink, AppTheme.accent],
                    ).createShader(const Rect.fromLTWH(0, 0, 160, 30)),
                ),
              ),
              TextSpan(
                text: 'eğlenceye',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.accentGold],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                ),
              ),
              const TextSpan(text: ' ortak ol!'),
              const TextSpan(
                text: '🎯',
                style: TextStyle(fontSize: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
