import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../data/datasources/live_api_remote_datasource.dart';
import '../../data/repositories/live_guest_repository_impl.dart';
import '../../data/services/live_namespace_socket_service.dart';
import '../../domain/repositories/live_guest_repository.dart';
import 'live_providers.dart';

final liveApiRemoteProvider = Provider<LiveApiRemoteDataSource>((ref) {
  return LiveApiRemoteDataSource(ref.watch(dioProvider));
});

final liveGuestRepositoryProvider = Provider<LiveGuestRepository>((ref) {
  return LiveGuestRepositoryImpl(
    ref.watch(liveApiRemoteProvider),
    ref.watch(liveStreamExtrasProvider),
  );
});

final liveNamespaceSocketProvider = Provider<LiveNamespaceSocketService>((ref) {
  final svc = LiveNamespaceSocketService();
  ref.onDispose(svc.disconnect);
  return svc;
});

/// Aktif PK maçları — `/api/live/pk/active` öncelikli.
final livePkActiveProvider =
    FutureProvider.autoDispose<List<PkRoomMatch>>((ref) async {
  return ref.read(liveApiRemoteProvider).fetchActivePk();
});

/// Misafir listesi — `/api/live/guest/list`.
final liveGuestListProvider = FutureProvider.autoDispose
    .family<dynamic, String?>((ref, streamId) async {
  return ref.read(liveGuestRepositoryProvider).fetchGuestList(streamId: streamId);
});

/// JWT okuyucu — `/live` namespace auth.
Future<String?> liveNamespaceAccessToken(Ref ref) async {
  return ref.read(tokenStorageProvider).readAccess();
}
