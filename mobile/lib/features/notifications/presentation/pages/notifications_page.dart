import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/notification_action.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../providers/notifications_list_notifier.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_permission_banner.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
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
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - ListPerf.preloadThresholdPx) {
      ref.read(notificationsListNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(notificationsListNotifierProvider.notifier).refresh();
    ref.invalidate(notificationsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(notificationsListNotifierProvider);
    final fmt = DateFormat('HH:mm');

    return DiscoverSubPage(
      title: 'Bildirimler',
      subtitle: 'Son aktiviteler ve uyarılar',
      onRefresh: _refresh,
      actions: [
        if (Env.useMobileAuth)
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              await _refresh();
            },
            child: Text('Tümünü oku'),
          ),
        DiscoverIconButton(
          icon: Icons.refresh_rounded,
          onPressed: _refresh,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NotificationPermissionBanner(),
          Expanded(
            child: list.when(
              loading: () => const DiscoverAccentLoader(),
              error: (e, _) => DiscoverEmptyState(
                icon: Icons.notifications_off_outlined,
                message: ApiException.userMessage(e),
                actionLabel: 'Yenile',
                action: _refresh,
              ),
              data: (state) {
                if (state.all.isEmpty) {
                  return const DiscoverEmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: 'Henüz bildirimin yok.',
                  );
                }
                return _NotificationsListView(
                  state: state,
                  fmt: fmt,
                  scrollController: _scroll,
                  onLoadMore: () => ref
                      .read(notificationsListNotifierProvider.notifier)
                      .loadMore(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsListView extends ConsumerWidget {
  const _NotificationsListView({
    required this.state,
    required this.fmt,
    required this.scrollController,
    required this.onLoadMore,
  });

  final NotificationsListState state;
  final DateFormat fmt;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = state.visible;
    final router = GoRouter.of(context);

    return ListView.separated(
      controller: scrollController,
      cacheExtent: ListPerf.cacheExtent,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        if (i >= items.length) {
          onLoadMore();
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final n = items[i];
        return ListPerf.repaint(
          ProGlassListTile(
            onTap: () async {
              if (!n.read) {
                await ref
                    .read(notificationsRepositoryProvider)
                    .markRead(n.id);
                await ref
                    .read(notificationsListNotifierProvider.notifier)
                    .refresh();
              }
              navigateFromNotification(router, n);
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: n.read ? null : context.colors.brandGradient,
                    color: n.read
                        ? Colors.white.withValues(alpha: 0.06)
                        : null,
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    size: 20,
                    color: n.read ? context.colors.onSurfaceMuted : Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          fontWeight:
                              n.read ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (n.body != null && n.body!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          n.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  fmt.format((n.createdAt ?? DateTime.now()).toLocal()),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
