import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Misafir katılma isteği — SSE / poll uyandırma.
final liveGuestJoinSignalProvider = StateProvider<int>((ref) => 0);

void bumpLiveGuestJoinSignal(WidgetRef ref) {
  ref.read(liveGuestJoinSignalProvider.notifier).state++;
}

void bumpLiveGuestJoinSignalReader(Ref ref) {
  ref.read(liveGuestJoinSignalProvider.notifier).state++;
}
