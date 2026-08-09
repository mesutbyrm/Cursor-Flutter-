import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/voice_event_log.dart';
import '../../domain/entities/voice_room_entity.dart';
import 'live_providers.dart';

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
