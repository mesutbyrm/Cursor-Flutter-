import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import 'notifications_list_notifier.dart';

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

/// Okunmamış bildirim sayısı (üst bar rozeti).
final notificationsUnreadCountProvider = Provider<int>((ref) {
  final fromList = ref.watch(notificationsListProvider);
  final fromNotifier = ref.watch(notificationsListNotifierProvider);
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
}
