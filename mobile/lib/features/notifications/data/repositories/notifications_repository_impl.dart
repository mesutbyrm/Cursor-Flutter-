import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../../../profile/data/datasources/canlifal_user_api_datasource.dart';
import '../../../profile/domain/entities/profile_stats_entity.dart';
import '../../../../core/config/env.dart';
import '../../../../core/offline/cache_first_loader.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote, this._canlifal);

  final NotificationsRemoteDataSource _remote;
  final CanlifalUserApiDataSource _canlifal;

  static const _cacheKey = 'notifications_list_v1';

  @override
  Future<List<AppNotificationEntity>> fetch() {
    return CacheFirstLoader.load(
      cacheKey: _cacheKey,
      maxAge: const Duration(minutes: 10),
      fetch: _fetchFresh,
      encode: (list) => {
        'items': list.map(_encodeNotification).toList(),
      },
      decode: (json) {
        final items = CacheFirstLoader.decodeListItems(json);
        return items.map(_decodeNotification).toList();
      },
    );
  }

  Future<List<AppNotificationEntity>> _fetchFresh() async {
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

  static Map<String, dynamic> _encodeNotification(AppNotificationEntity n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'read': n.read,
        'createdAt': n.createdAt?.toIso8601String(),
        'type': n.type,
      };

  static AppNotificationEntity _decodeNotification(Map<String, dynamic> json) {
    return AppNotificationEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      type: json['type']?.toString(),
    );
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
