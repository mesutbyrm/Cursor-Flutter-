import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';
import '../providers/feed_unread_providers.dart';
import '../widgets/feed_composer_bar.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/feed_story_strip.dart';
import '../widgets/feed_voice_room_strip.dart';

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

  List<Widget> _contentSlots(List<PostEntity> posts) {
    final list = <Widget>[
      FeedStoryStrip(posts: posts),
      const FeedComposerBar(),
    ];
    for (var i = 0; i < posts.length; i++) {
      list.add(FeedPostCard(post: posts[i]));
      if (i % 2 == 1) {
        list.add(const FeedVoiceRoomStrip());
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedNotifierProvider);
    final unreadN = ref.watch(unreadNotificationCountProvider);
    final unreadM = ref.watch(unreadMessagesCountProvider);

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
          _BadgeIcon(
            showDot: unreadN > 0,
            icon: Icons.notifications_none_rounded,
            onPressed: () => context.push('/notifications'),
          ),
          _BadgeIcon(
            showDot: unreadM > 0,
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => ref.read(feedNotifierProvider.notifier).refresh(),
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
            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () =>
                  ref.read(feedNotifierProvider.notifier).refresh(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  12,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                  12,
                  100,
                ),
                children: [
                  ..._contentSlots(posts),
                  const SizedBox(height: 24),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () =>
                ref.read(feedNotifierProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels > n.metrics.maxScrollExtent - 500) {
                  ref.read(feedNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  0,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
                  0,
                  100,
                ),
                children: _contentSlots(posts),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.onPressed,
    required this.showDot,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (showDot)
            Positioned(
              right: 2,
              top: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.background,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
