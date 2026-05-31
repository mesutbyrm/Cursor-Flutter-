import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';

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
  return ref.watch(notificationsRepositoryProvider).fetch();
});
