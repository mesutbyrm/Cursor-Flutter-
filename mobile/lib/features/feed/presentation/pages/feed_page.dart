import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/feed_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedNotifierProvider);

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
            onPressed: () =>
                ref.read(feedNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(feedNotifierProvider.notifier).refresh(),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('Henüz gönderi yok'));
          }
          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () =>
                ref.read(feedNotifierProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >
                    n.metrics.maxScrollExtent - 500) {
                  ref.read(feedNotifierProvider.notifier).loadMore();
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
                  final p = posts[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 9 / 14,
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
                                                  fontWeight: FontWeight.w700,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
