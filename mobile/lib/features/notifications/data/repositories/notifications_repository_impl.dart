import '../../../../core/config/env.dart';
import '../../../profile/data/datasources/canlifal_user_api_datasource.dart';
import '../../../profile/domain/entities/profile_stats_entity.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote, this._canlifal);

  final NotificationsRemoteDataSource _remote;
  final CanlifalUserApiDataSource _canlifal;

  @override
  Future<List<AppNotificationEntity>> fetch() async {
    final byId = <String, AppNotificationEntity>{};

    void addAll(Iterable<AppNotificationEntity> items) {
      for (final n in items) {
        final key = n.id.isNotEmpty ? n.id : '${n.title}_${n.createdAt}';
        byId.putIfAbsent(key, () => n);
      }
    }

    try {
      addAll(await _remote.list());
    } catch (_) {}

    if (Env.useMobileAuth) {
      try {
        final page = await _canlifal.fetchActivity();
        addAll(page.items.map(_activityToNotification));
      } catch (_) {}
    }

    final list = byId.values.toList()
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    return list;
  }

  AppNotificationEntity _activityToNotification(ProfileActivityItemEntity a) {
    final read = a.status.toLowerCase() == 'read' ||
        a.status.toLowerCase() == 'seen';
    return AppNotificationEntity(
      id: a.id,
      title: a.title,
      body: a.subtitle,
      read: read,
      createdAt: DateTime.tryParse(a.createdAt ?? ''),
      type: a.type,
    );
  }

  @override
  Future<void> markRead(String id) async {
    if (Env.useMobileAuth) {
      try {
        await _canlifal.markActivityRead(id);
        return;
      } catch (_) {}
    }
    try {
      await _remote.markRead(id);
    } catch (_) {}
  }

  @override
  Future<void> markAllRead() async {
    if (Env.useMobileAuth) {
      await _canlifal.markAllActivityRead();
    }
  }
}
