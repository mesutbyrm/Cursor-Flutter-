import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../../fortune/presentation/providers/fortune_api_providers.dart';
import '../../domain/entities/user_favorite_entity.dart';
import '../providers/favorites_providers.dart';

/// Site `/favoriler` — fal geçmişi + native favori listesi.
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Favoriler'),
        actions: [
          IconButton(
            tooltip: 'Site favorileri',
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () => context.push(
              CanlifalWebRoute.location(
                relativePath: '/favoriler',
                title: 'Kayıtlı favoriler',
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Fal geçmişim'),
            Tab(text: 'Kayıtlılarım'),
          ],
          labelColor: palette.textPrimary,
          unselectedLabelColor: palette.textMuted,
          indicatorColor: palette.colors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _FortuneHistoryTab(),
          _SavedFavoritesTab(),
        ],
      ),
    );
  }
}

class _FortuneHistoryTab extends ConsumerWidget {
  const _FortuneHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final history = ref.watch(fortuneHistoryProvider);

    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(context),
          child: Text(
            ApiException.userMessage(e),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: ResponsiveLayout.pagePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: palette.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz fal geçmişiniz yok.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/fortune'),
                    child: const Text('Fal baktır'),
                  ),
                ],
              ),
            ),
          );
        }

        final notifier = ref.read(fortuneHistoryProvider.notifier);
        final dateFmt = DateFormat('d MMM yyyy, HH:mm', 'tr');

        return RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                notifier.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: ResponsiveLayout.pagePadding(context).copyWith(
                top: 12,
                bottom: 32,
              ),
              itemCount: items.length + (notifier.canLoadMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i >= items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final f = items[i];
                final when = f.createdAt != null
                    ? dateFmt.format(f.createdAt!.toLocal())
                    : null;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          palette.colors.primary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: palette.colors.primary,
                      ),
                    ),
                    title: Text(
                      f.displayTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (f.displayBody.isNotEmpty)
                          Text(
                            f.displayBody,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (when != null)
                          Text(
                            when,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => context.push('/fortune/history/${f.id}'),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SavedFavoritesTab extends ConsumerWidget {
  const _SavedFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final favorites = ref.watch(userFavoritesProvider);

    return favorites.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          ApiException.userMessage(e),
          textAlign: TextAlign.center,
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: ResponsiveLayout.pagePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 48,
                    color: palette.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz kayıtlı favoriniz yok.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userFavoritesProvider),
          child: ListView.separated(
            padding: ResponsiveLayout.pagePadding(context).copyWith(
              top: 12,
              bottom: 32,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(color: palette.divider),
            itemBuilder: (context, i) {
              final f = items[i];
              return Dismissible(
                key: ValueKey(f.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: context.liveRed.withValues(alpha: 0.85),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white),
                ),
                onDismissed: (_) async {
                  await ref.read(favoritesRepositoryProvider).remove(f.id);
                  ref.invalidate(userFavoritesProvider);
                },
                child: ListTile(
                  leading: Icon(
                    _iconForType(f.targetType),
                    color: palette.colors.primary,
                  ),
                  title: Text(
                    f.title ?? f.targetId,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    f.targetType,
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                  onTap: () => _openFavorite(context, f),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'user' => Icons.person_rounded,
      'post' => Icons.article_rounded,
      'fortune' => Icons.auto_awesome_rounded,
      'room' => Icons.mic_rounded,
      _ => Icons.link_rounded,
    };
  }

  void _openFavorite(BuildContext context, UserFavoriteEntity f) {
    switch (f.targetType) {
      case 'user':
        context.push('/user/${f.targetId}');
      case 'fortune':
        context.push('/fortune/history/${f.targetId}');
      case 'post':
        context.go('/social');
      case 'room':
        context.push('/voice-room/${f.targetId}');
      default:
        if (f.url != null && f.url!.startsWith('/')) {
          context.push(
            CanlifalWebRoute.location(
              relativePath: f.url!,
              title: f.title ?? 'İçerik',
            ),
          );
        }
    }
  }
}
