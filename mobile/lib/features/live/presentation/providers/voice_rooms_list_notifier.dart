import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/voice_event_log.dart';
import '../../domain/entities/voice_room_entity.dart';
import 'live_providers.dart';

/// Yerel oda listesinde tek satırı güncelle (test edilebilir saf fonksiyon).
List<VoiceRoomEntity> patchVoiceRoomsInList(
  List<VoiceRoomEntity> current,
  String roomKey,
  VoiceRoomEntity Function(VoiceRoomEntity room) transform,
) {
  final key = roomKey.trim();
  if (key.isEmpty) return current;
  final lower = key.toLowerCase();
  var changed = false;
  final next = <VoiceRoomEntity>[];
  for (final r in current) {
    final id = r.id.trim().toLowerCase();
    final slug = r.slug.trim().toLowerCase();
    final matches = id == lower ||
        slug == lower ||
        r.apiRoomKey.trim().toLowerCase() == lower ||
        (key.length >= 6 && id.startsWith(lower));
    if (matches) {
      changed = true;
      next.add(transform(r));
    } else {
      next.add(r);
    }
  }
  return changed ? next : current;
}

/// Sesli oda listesi — sayfalanmış yükleme (açılışta tüm odalar çekilmez).
class VoiceRoomsListNotifier extends AsyncNotifier<List<VoiceRoomEntity>> {
  static const _pageSize = 30;

  var _page = 1;
  var _hasMore = true;
  var _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<VoiceRoomEntity>> build() async {
    _page = 1;
    _hasMore = true;
    final result = await ref
        .read(liveRepositoryProvider)
        .fetchVoiceRoomsPage(page: 1, limit: _pageSize);
    _hasMore = result.hasMore;
    VoiceEventLog.roomListLoad(page: 1, count: result.rooms.length);
    return result.rooms;
  }

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncValue<List<VoiceRoomEntity>>.loading()
        .copyWithPrevious(previous);
    _page = 1;
    _hasMore = true;
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(liveRepositoryProvider)
          .fetchVoiceRoomsPage(page: 1, limit: _pageSize);
      _hasMore = result.hasMore;
      VoiceEventLog.roomListLoad(page: 1, count: result.rooms.length);
      return result.rooms;
    });
  }

  /// Yerel liste önbelleğinde tek oda alanlarını güncelle (ayar PATCH sonrası).
  void patchRoomFields(
    String roomKey,
    VoiceRoomEntity Function(VoiceRoomEntity room) transform,
  ) {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = patchVoiceRoomsInList(current, roomKey, transform);
    if (!identical(next, current)) state = AsyncValue.data(next);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.valueOrNull;
    if (current == null) return;
    _loadingMore = true;
    try {
      final nextPage = _page + 1;
      final result = await ref
          .read(liveRepositoryProvider)
          .fetchVoiceRoomsPage(page: nextPage, limit: _pageSize);
      _page = nextPage;
      _hasMore = result.hasMore;
      if (result.rooms.isEmpty) {
        _hasMore = false;
        return;
      }
      final seen = current.map((r) => r.apiRoomKey).toSet();
      final merged = [
        ...current,
        ...result.rooms.where((r) => seen.add(r.apiRoomKey)),
      ];
      VoiceEventLog.roomListLoad(page: nextPage, count: merged.length);
      state = AsyncValue.data(merged);
    } finally {
      _loadingMore = false;
    }
  }
}

final voiceRoomsListNotifierProvider =
    AsyncNotifierProvider<VoiceRoomsListNotifier, List<VoiceRoomEntity>>(
  VoiceRoomsListNotifier.new,
);

final voiceRoomsHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(voiceRoomsListNotifierProvider.notifier).hasMore;
});

final voiceRoomsLoadingMoreProvider = Provider<bool>((ref) {
  return ref.watch(voiceRoomsListNotifierProvider.notifier).isLoadingMore;
});
