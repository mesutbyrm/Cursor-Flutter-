import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/gift_box_models.dart';
import 'gift_box_providers.dart';

/// Oda veya yayın kapsamı — yalnızca biri dolu olmalı.
typedef GiftBoxScope = ({String? roomId, String? streamId});

final giftBoxSnapshotProvider =
    FutureProvider.autoDispose.family<GiftBoxListSnapshot, GiftBoxScope>(
  (ref, scope) async {
    final repo = ref.watch(giftBoxRepositoryProvider);
    final raw = await repo.listActive(
      roomId: scope.roomId,
      streamId: scope.streamId,
    );
    return GiftBoxListSnapshot.fromApi(raw);
  },
);

/// SSE `gift_box_*` sonrası panel yenileme sinyali.
final giftBoxRefreshTickProvider =
    StateProvider.autoDispose.family<int, GiftBoxScope>((ref, scope) => 0);

void bumpGiftBoxRefresh(Ref ref, GiftBoxScope scope) {
  ref.read(giftBoxRefreshTickProvider(scope).notifier).state++;
  ref.invalidate(giftBoxSnapshotProvider(scope));
}
