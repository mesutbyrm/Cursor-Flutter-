import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';

final notificationsRemoteProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSource(ref.watch(dioProvider));
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(notificationsRemoteProvider));
});

final notificationsListProvider =
    FutureProvider<List<AppNotificationEntity>>((ref) async {
  ref.keepAlive();
  return ref.watch(notificationsRepositoryProvider).fetch();
});

/// Okunmamış bildirim sayısı (üst bar rozeti).
final notificationsUnreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsListProvider);
  return list.maybeWhen(
    data: (items) => items.where((n) => !n.read).length,
    orElse: () => 0,
  );
});
