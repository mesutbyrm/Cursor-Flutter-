import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/social_refresh_indicator.dart';
import '../providers/notifications_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsListProvider);
    final refreshEdge = MediaQuery.paddingOf(context).top + kToolbarHeight + 4;

    Future<void> onPullRefresh() async {
      ref.invalidate(notificationsListProvider);
      await ref.read(notificationsListProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(notificationsListProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return SocialRefreshIndicator(
              edgeOffset: refreshEdge,
              onRefresh: onPullRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Bildirim yok',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final fmt = DateFormat('HH:mm');
          return SocialRefreshIndicator(
            edgeOffset: refreshEdge,
            onRefresh: onPullRefresh,
            child: ListView.separated(
              cacheExtent: 600,
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = items[i];
                return Material(
                  color: n.read ? AppTheme.surface : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      if (!n.read) {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markRead(n.id);
                        ref.invalidate(notificationsListProvider);
                      }
                    },
                    child: ListTile(
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.read
                              ? FontWeight.w500
                              : FontWeight.w800,
                        ),
                      ),
                      subtitle: n.body != null
                          ? Text(
                              n.body!,
                              style: const TextStyle(color: AppTheme.muted),
                            )
                          : null,
                      trailing: n.createdAt != null
                          ? Text(
                              fmt.format(n.createdAt!.toLocal()),
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
