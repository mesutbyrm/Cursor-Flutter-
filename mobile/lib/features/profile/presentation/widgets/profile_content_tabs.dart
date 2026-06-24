import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../fortune/domain/entities/user_fortune_entity.dart';
import '../../../fortune/presentation/providers/fortune_api_providers.dart';
import '../../../shorts/domain/entities/short_video_entity.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import 'user_posts_tiktok_grid.dart';

/// TikTok tarzı profil sekmeleri: videolar, fallar, izlediklerim.
class ProfileContentTabs extends ConsumerStatefulWidget {
  const ProfileContentTabs({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfileContentTabs> createState() => _ProfileContentTabsState();
}

class _ProfileContentTabsState extends ConsumerState<ProfileContentTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          indicatorColor: AppThemeColors.accentPink,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Videolarım'),
            Tab(text: 'Fallarım'),
            Tab(text: 'İzlediklerim'),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _tabs,
          builder: (context, _) {
            switch (_tabs.index) {
              case 1:
                return _FortuneTab(userId: widget.userId);
              case 2:
                return const _WatchedTab();
              default:
                return UserPostsTikTokGrid(userId: widget.userId);
            }
          },
        ),
      ],
    );
  }
}

class _FortuneTab extends ConsumerWidget {
  const _FortuneTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(fortuneHistoryProvider);

    return history.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Fallar yüklenemedi', style: TextStyle(color: context.colors.onSurfaceMuted)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Henüz fal kaydı yok')),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final f = items[index];
            return _FortuneTile(fortune: f);
          },
        );
      },
    );
  }
}

class _FortuneTile extends StatelessWidget {
  const _FortuneTile({required this.fortune});

  final UserFortuneEntity fortune;

  @override
  Widget build(BuildContext context) {
    final title = fortune.summary?.trim().isNotEmpty == true
        ? fortune.summary!
        : fortune.type;
    return ListTile(
      onTap: () => context.push('/fortune/detail/${fortune.id}'),
      tileColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F)),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        (fortune.createdAt ?? DateTime.now()).toLocal().toString().split('.').first,
        style: TextStyle(fontSize: 11, color: context.colors.onSurfaceMuted),
      ),
    );
  }
}

class _WatchedTab extends ConsumerWidget {
  const _WatchedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(viewedShortsProvider);

    return watched.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text('İzleme geçmişi yüklenemedi'),
      ),
      data: (videos) {
        if (videos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Henüz izlenen video yok')),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 9 / 16,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) => _WatchedTile(video: videos[index]),
        );
      },
    );
  }
}

class _WatchedTile extends StatelessWidget {
  const _WatchedTile({required this.video});

  final ShortVideoEntity video;

  @override
  Widget build(BuildContext context) {
    final thumb = video.thumbnailUrl;
    return GestureDetector(
      onTap: () => context.push('/shorts'),
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFF1A0F3D)),
        child: thumb != null && thumb.isNotEmpty
            ? CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover)
            : const Center(child: Icon(Icons.play_circle_outline_rounded)),
      ),
    );
  }
}
