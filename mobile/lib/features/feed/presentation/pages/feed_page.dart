import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../live/presentation/providers/live_providers.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedNotifierProvider);
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppTheme.accentSecondary, AppTheme.accent],
          ).createShader(b),
          child: const Text(
            'Canlifal',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _refreshHome,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
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
              SliverPadding(
                padding: EdgeInsets.fromLTRB(12, topPad, 12, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      FeedLiveStrip(),
                      FeedVoiceRoomsStrip(),
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
              else if (feed.hasValue && feed.requireValue.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories_outlined,
                            size: 56, color: AppTheme.muted),
                        const SizedBox(height: 16),
                        Text(
                          Env.useNextAuth
                              ? 'Henüz gönderi yok.\n'
                                  'İçerik sunucudan geldikçe listelenir; canlifal.com ile aynı hesaptan giriş yaptığınızdan emin olun.'
                              : 'Henüz gönderi yok.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (feed.hasValue)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
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
                                                  '/user/${p.author.id}',
                                                ),
                                                child: Row(
                                                  children: [
                                                    UserAvatar(
                                                      url: p.author.avatarUrl,
                                                      radius: 18,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      p.author.display,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              const Icon(Icons.favorite_border,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
