import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../domain/entities/app_notification_entity.dart';
import 'notifications_providers.dart';

class NotificationsListState {
  const NotificationsListState({
    required this.all,
    this.visibleCount = ListPerf.defaultPageSize,
  });

  final List<AppNotificationEntity> all;
  final int visibleCount;

  bool get hasMore => visibleCount < all.length;

  List<AppNotificationEntity> get visible =>
      all.take(visibleCount.clamp(0, all.length)).toList();

  NotificationsListState copyWith({
    List<AppNotificationEntity>? all,
    int? visibleCount,
  }) {
    return NotificationsListState(
      all: all ?? this.all,
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }
}

class NotificationsListNotifier extends AsyncNotifier<NotificationsListState> {
  @override
  Future<NotificationsListState> build() async {
    ref.keepAlive();
    final all = await ref.read(notificationsRepositoryProvider).fetch();
    final visible = ListPerf.defaultPageSize.clamp(0, all.length);
    return NotificationsListState(all: all, visibleCount: visible);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<NotificationsListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final all = await ref
          .read(notificationsRepositoryProvider)
          .fetch(forceRefresh: true);
      final visible = ListPerf.defaultPageSize.clamp(0, all.length);
      return NotificationsListState(all: all, visibleCount: visible);
    });
  }

  void markOneReadLocally(String id) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(
      cur.copyWith(
        all: [
          for (final n in cur.all)
            if (n.id == id)
              AppNotificationEntity(
                id: n.id,
                title: n.title,
                body: n.body,
                read: true,
                createdAt: n.createdAt,
                type: n.type,
                targetPath: n.targetPath,
                targetId: n.targetId,
              )
            else
              n,
        ],
      ),
    );
  }

  void markAllReadLocally() {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(
      cur.copyWith(
        all: [
          for (final n in cur.all)
            AppNotificationEntity(
              id: n.id,
              title: n.title,
              body: n.body,
              read: true,
              createdAt: n.createdAt,
              type: n.type,
              targetPath: n.targetPath,
              targetId: n.targetId,
            ),
        ],
      ),
    );
  }

  void loadMore() {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore) return;
    state = AsyncValue.data(
      cur.copyWith(
        visibleCount: (cur.visibleCount + ListPerf.defaultPageSize)
            .clamp(0, cur.all.length),
      ),
    );
  }
}

final notificationsListNotifierProvider =
    AsyncNotifierProvider<NotificationsListNotifier, NotificationsListState>(
  NotificationsListNotifier.new,
);
