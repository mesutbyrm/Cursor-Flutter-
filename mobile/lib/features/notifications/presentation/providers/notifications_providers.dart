import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import 'notifications_list_notifier.dart';
import '../../../inbox/domain/system_notifications_read_sync.dart';

final notificationsRemoteProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSource(ref.watch(dioProvider));
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteProvider),
    ref.watch(canlifalUserApiProvider),
  );
});

final notificationsListProvider =
    FutureProvider<List<AppNotificationEntity>>((ref) async {
  ref.keepAlive();
  return ref.watch(notificationsRepositoryProvider).fetch();
});

/// Backend unread count — `GET /api/notifications?unreadOnly=true` (yedek: messages)
final notificationsUnreadApiProvider = FutureProvider<int?>((ref) async {
  final userId = ref.watch(
    authControllerProvider.select((a) => a.valueOrNull?.id),
  );
  if (userId == null || userId.isEmpty) return 0;
  return ref.watch(notificationsRemoteProvider).fetchUnreadCount();
});

/// Okunmamış bildirim sayısı (üst bar rozeti).
final notificationsUnreadCountProvider = Provider<int>((ref) {
  final api = ref.watch(notificationsUnreadApiProvider);
  final apiCount = api.valueOrNull;
  if (apiCount != null && apiCount >= 0) return apiCount;

  final fromNotifier = ref.watch(notificationsListNotifierProvider);
  final fromList = ref.watch(notificationsListProvider);
  final items = fromNotifier.valueOrNull?.all ??
      fromList.valueOrNull ??
      const <AppNotificationEntity>[];
  return items.where((n) => !n.read).length;
});

/// Bildirim rozeti sıfırlama — liste + sunucu senkronu.
Future<void> markAllNotificationsRead(WidgetRef ref) async {
  ref.read(notificationsListNotifierProvider.notifier).markAllReadLocally();
  try {
    await ref.read(notificationsRepositoryProvider).markAllRead();
  } catch (_) {}
  ref.invalidate(notificationsListProvider);
  ref.invalidate(notificationsListNotifierProvider);
  ref.invalidate(notificationsUnreadApiProvider);
}

/// Tek bildirim okundu — optimistic + API; başarısızsa geri al.
Future<void> markNotificationRead(WidgetRef ref, String id) async {
  ref.read(notificationsListNotifierProvider.notifier).markOneReadLocally(id);
  try {
    await ref.read(notificationsRepositoryProvider).markRead(id);
    ref.invalidate(notificationsUnreadApiProvider);
  } catch (_) {
    await ref.read(notificationsListNotifierProvider.notifier).refresh();
  }
}

/// Sistem Mesajları ekranı: yalnız sistem bildirimlerini sunucuda okundu yapar,
/// başarıdan SONRA yerel listeyi ve rozetleri günceller. Hata fırlatır; yerel
/// durum değişmez (öğeler okunmuş gibi gösterilmez).
Future<int> markSystemNotificationsRead(WidgetRef ref) async {
  // Önce liste yüklensin (görünen öğeler sunucu durumuyla gelir), sonra işaretle.
  try {
    await ref.read(notificationsListNotifierProvider.future);
  } catch (_) {}
  final remote = ref.read(notificationsRemoteProvider);
  final ids = await SystemNotificationsReadSync(
    fetchUnreadPage: remote.fetchUnreadPage,
    markReadIds: remote.markReadIds,
    pageSize: NotificationsRemoteDataSource.unreadPageSize,
  ).run();
  ref.read(notificationsListNotifierProvider.notifier).markIdsReadLocally(ids);
  ref.invalidate(notificationsListProvider);
  ref.invalidate(notificationsUnreadApiProvider);
  return ids.length;
}
