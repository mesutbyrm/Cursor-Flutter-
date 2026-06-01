import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../providers/favorites_providers.dart';

/// Site `/favoriler` — fal geçmişi (API) + web kayıtlı içerik (WebView).
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
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Fal geçmişim'),
            Tab(text: 'Kayıtlı'),
          ],
          labelColor: palette.textPrimary,
          unselectedLabelColor: palette.textMuted,
          indicatorColor: palette.colors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FortuneHistoryTab(),
          _SiteFavoritesWebTab(),
        ],
      ),
    );
  }
}

class _FortuneHistoryTab extends ConsumerWidget {
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                      f.type.isNotEmpty ? f.type : 'Fal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (f.question != null && f.question!.isNotEmpty)
                          Text(
                            f.question!,
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

class _SiteFavoritesWebTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_rounded, size: 48, color: palette.colors.primary),
            const SizedBox(height: 12),
            Text(
              'Sitede kaydettiğiniz içerikler web hesabınızla senkronize edilir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push(
                CanlifalWebRoute.location(
                  relativePath: '/favoriler',
                  title: 'Kayıtlı favoriler',
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Site favorilerini aç'),
            ),
          ],
        ),
      ),
    );
  }
}
