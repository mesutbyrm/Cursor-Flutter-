import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_stream_entity.dart';
import 'live_streams_list_notifier.dart';

/// Canlı yayın keşif listesi — tek kaynak (`liveStreamsListNotifierProvider`).
void invalidateDiscoverLiveStreams(Ref ref) {
  ref.invalidate(liveStreamsListNotifierProvider);
}

/// Geriye dönük: keşif listesinin ilk sayfası (çift fetch önlenir).
final liveStreamsProvider = FutureProvider<List<LiveStreamEntity>>((ref) async {
  final cached = ref.watch(liveStreamsListNotifierProvider).valueOrNull;
  if (cached != null) return cached;
  return ref.read(liveStreamsListNotifierProvider.future);
});
