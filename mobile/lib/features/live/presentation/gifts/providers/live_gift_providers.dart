import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../data/datasources/live_gifts_remote_datasource.dart';
import '../../../data/services/live_gift_realtime_service.dart';
import '../../../data/services/live_gift_socket_bridge.dart';
import '../../../domain/entities/live_gift_type.dart';
import '../live_gift_controller.dart';

final liveGiftsRemoteProvider = Provider<LiveGiftsRemoteDataSource>((ref) {
  return LiveGiftsRemoteDataSource(ref.watch(dioProvider));
});

final liveGiftSocketBridgeProvider = Provider<LiveGiftSocketBridge>((ref) {
  return LiveGiftSocketBridge(ref.watch(liveGiftsRemoteProvider));
});

final liveGiftRealtimeProvider = Provider<LiveGiftRealtimeService>((ref) {
  final svc = LiveGiftRealtimeService(
    ref.watch(liveGiftsRemoteProvider),
    ref.watch(liveGiftSocketBridgeProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});

final liveGiftControllerProvider =
    ChangeNotifierProvider.autoDispose<LiveGiftController>((ref) {
  final c = LiveGiftController(
    remote: ref.watch(liveGiftsRemoteProvider),
    realtime: ref.watch(liveGiftRealtimeProvider),
  );
  ref.onDispose(c.dispose);
  return c;
});

final liveGiftTypesProvider =
    FutureProvider.autoDispose<List<LiveVideoGiftType>>((ref) async {
  return ref.watch(liveGiftsRemoteProvider).fetchGiftTypes();
});
