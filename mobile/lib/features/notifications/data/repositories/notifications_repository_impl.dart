import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../../../profile/data/datasources/canlifal_user_api_datasource.dart';
import '../../../profile/domain/entities/profile_stats_entity.dart';
import '../../../../core/config/env.dart';
import '../../../../core/performance/network_perf.dart';
import '../../../../core/offline/api_cache_store.dart';
import '../../../../core/offline/cache_first_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote, this._canlifal);

  final NotificationsRemoteDataSource _remote;
  final CanlifalUserApiDataSource _canlifal;

  static const _cacheKey = 'notifications_list_v1';
  static const _readIdsKey = 'notifications_read_ids_v1';
  static const _readAllBeforeKey = 'notifications_read_all_before_ms_v1';

  @override
  Future<List<AppNotificationEntity>> fetch({bool forceRefresh = false}) {
    return CacheFirstLoader.load(
      cacheKey: _cacheKey,
      maxAge: const Duration(minutes: 10),
      forceRefresh: forceRefresh,
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
        final fingerprint = _notificationFingerprint(n);
        final idKey = n.id.trim();
        if (idKey.isNotEmpty) {
          final existing = byId[idKey];
          if (existing != null) {
            if (!existing.read && n.read) {
              byId[idKey] = n;
            }
            continue;
          }
          byId[idKey] = n;
          continue;
        }
        byId.putIfAbsent(fingerprint, () => n);
      }
    }

    final pair = await NetworkPerf.parallel([
      () async {
        try {
          return await _remote.list();
        } catch (_) {
          return <AppNotificationEntity>[];
        }
      }(),
      () async {
        if (!Env.useMobileAuth) return <ProfileActivityItemEntity>[];
        try {
          final page = await _canlifal.fetchActivity();
          return page.items;
        } catch (_) {
          return <ProfileActivityItemEntity>[];
        }
      }(),
    ]);
    addAll(pair[0] as List<AppNotificationEntity>);
    addAll(
      (pair[1] as List<ProfileActivityItemEntity>).map(_activityToNotification),
    );

    final localRead = await _NotificationReadMemory.load();
    final list = _dedupeMergedNotifications(byId.values.toList())
        .map(localRead.apply)
        .toList()
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    return list;
  }

  static String _notificationFingerprint(AppNotificationEntity n) {
    final created = n.createdAt?.toIso8601String() ?? '';
    return [
      n.type?.toLowerCase().trim() ?? '',
      n.title.trim().toLowerCase(),
      n.body?.trim().toLowerCase() ?? '',
      n.targetId?.trim() ?? '',
      n.targetPath?.trim() ?? '',
      created,
    ].join('|');
  }

  static List<AppNotificationEntity> _dedupeMergedNotifications(
    List<AppNotificationEntity> items,
  ) {
    final seenIds = <String>{};
    final seenFingerprints = <String>{};
    final out = <AppNotificationEntity>[];
    for (final item in items) {
      final id = item.id.trim();
      if (id.isNotEmpty && !seenIds.add(id)) continue;
      final fingerprint = _notificationFingerprint(item);
      if (fingerprint.replaceAll('|', '').isNotEmpty &&
          !seenFingerprints.add(fingerprint)) {
        continue;
      }
      out.add(item);
    }
    return out;
  }

  static Map<String, dynamic> _encodeNotification(AppNotificationEntity n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'read': n.read,
        'createdAt': n.createdAt?.toIso8601String(),
        'type': n.type,
        'targetPath': n.targetPath,
        'targetId': n.targetId,
        'imageUrl': n.imageUrl,
        'senderId': n.senderId,
      };

  static AppNotificationEntity _decodeNotification(Map<String, dynamic> json) {
    return AppNotificationEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      type: json['type']?.toString(),
      targetPath: json['targetPath']?.toString(),
      targetId: json['targetId']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      senderId: json['senderId']?.toString(),
    );
  }

  AppNotificationEntity _activityToNotification(ProfileActivityItemEntity a) {
    final status = a.status.toLowerCase();
    final read = status == 'read' ||
        status == 'seen' ||
        status == 'approved' ||
        status == 'completed' ||
        status == 'rejected';
    return AppNotificationEntity(
      id: a.id,
      title: a.title,
      body: a.subtitle,
      read: read,
      createdAt: DateTime.tryParse(a.createdAt ?? ''),
      type: a.type,
      targetPath: a.targetPath,
      targetId: a.targetId,
    );
  }

  /// Logout — yerel okundu hafızasını temizle (kullanıcılar arası sızıntı önleme).
  static Future<void> clearLocalReadState() =>
      _NotificationReadMemory.clearAll();

  Future<void> _invalidateCache() => ApiCacheStore.clear(_cacheKey);

  @override
  Future<void> markRead(String id) async {
    await _invalidateCache();
    await _NotificationReadMemory.markIdRead(id);
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
    await _invalidateCache();
    await _NotificationReadMemory.markAllReadBeforeNow();
    if (Env.useMobileAuth) {
      await _canlifal.markAllActivityRead();
    }
    try {
      await _remote.markAllRead();
    } catch (_) {}
  }

  @override
  Future<void> clearPaymentNotifications() async {
    try {
      await _remote.clearPaymentNotifications();
    } catch (_) {}
  }
}

class _NotificationReadMemory {
  const _NotificationReadMemory({
    required this.readIds,
    required this.readAllBeforeMs,
  });

  final Set<String> readIds;
  final int readAllBeforeMs;

  static Future<_NotificationReadMemory> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _NotificationReadMemory(
      readIds: prefs.getStringList(NotificationsRepositoryImpl._readIdsKey)
              ?.toSet() ??
          const <String>{},
      readAllBeforeMs:
          prefs.getInt(NotificationsRepositoryImpl._readAllBeforeKey) ?? 0,
    );
  }

  static Future<void> markIdRead(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs
            .getStringList(NotificationsRepositoryImpl._readIdsKey)
            ?.toSet() ??
        <String>{};
    ids.add(trimmed);
    // Keep the preference bounded; old entries are still covered by read-all cutoff.
    final compact = ids.length > 500 ? ids.toList().skip(ids.length - 500) : ids;
    await prefs.setStringList(
      NotificationsRepositoryImpl._readIdsKey,
      compact.toList(),
    );
  }

  static Future<void> markAllReadBeforeNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      NotificationsRepositoryImpl._readAllBeforeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(NotificationsRepositoryImpl._readIdsKey);
    await prefs.remove(NotificationsRepositoryImpl._readAllBeforeKey);
  }

  AppNotificationEntity apply(AppNotificationEntity n) {
    if (n.read) return n;
    final idRead = n.id.trim().isNotEmpty && readIds.contains(n.id.trim());
    final created = n.createdAt?.millisecondsSinceEpoch;
    final coveredByReadAll = created != null &&
        readAllBeforeMs > 0 &&
        created <= readAllBeforeMs;
    if (!idRead && !coveredByReadAll) return n;
    return AppNotificationEntity(
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
    );
  }
}
