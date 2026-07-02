import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aktif oynatılması gereken video — sayfa değişince merkezi tetikleme.
final shortsActiveVideoIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Oynatma isteği sayacı — aynı video tekrar tetiklensin diye artırılır.
final shortsPlaybackTickProvider = StateProvider.autoDispose<int>((ref) => 0);

void requestShortsPlayback(WidgetRef ref, String videoId) {
  ref.read(shortsActiveVideoIdProvider.notifier).state = videoId;
  ref.read(shortsPlaybackTickProvider.notifier).state =
      ref.read(shortsPlaybackTickProvider) + 1;
}
