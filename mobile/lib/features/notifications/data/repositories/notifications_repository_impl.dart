import '../../../../core/config/env.dart';
import '../../../profile/data/datasources/canlifal_user_api_datasource.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote, this._canlifal);

  final NotificationsRemoteDataSource _remote;
  final CanlifalUserApiDataSource _canlifal;

  @override
  Future<List<AppNotificationEntity>> fetch() async {
    if (Env.useNextAuth) {
      try {
        final items = await _canlifal.fetchActivity();
        if (items.isNotEmpty) {
          return items
              .map(
                (a) => AppNotificationEntity(
                  id: a.id,
                  title: a.title,
                  body: a.body,
                  read: a.read,
                  createdAt: a.createdAt,
                ),
              )
              .toList();
        }
      } catch (_) {}
    }
    return _remote.list();
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _remote.markRead(id);
    } catch (_) {}
  }

  @override
  Future<void> markAllRead() async {
    if (Env.useNextAuth) {
      await _canlifal.markAllActivityRead();
      return;
    }
  }
}
