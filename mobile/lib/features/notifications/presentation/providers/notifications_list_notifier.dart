import 'dart:async';

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
                imageUrl: n.imageUrl,
                senderId: n.senderId,
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
              imageUrl: n.imageUrl,
              senderId: n.senderId,
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

  /// SSE ile gelen yeni bildirim — listeye başa ekle.
  void prepend(AppNotificationEntity notification) {
    final cur = state.valueOrNull;
    if (cur == null) {
      unawaited(refresh());
      return;
    }
    final withoutDup = [
      for (final n in cur.all)
        if (n.id != notification.id) n,
    ];
    state = AsyncValue.data(
      cur.copyWith(
        all: [notification, ...withoutDup],
        visibleCount: (cur.visibleCount + 1).clamp(0, withoutDup.length + 1),
      ),
    );
  }
}

final notificationsListNotifierProvider =
    AsyncNotifierProvider<NotificationsListNotifier, NotificationsListState>(
  NotificationsListNotifier.new,
);
