import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ortak yayın daveti — stream SSE sonrası global dinleyiciyi uyandırır.
class LiveCoBroadcastInviteSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final liveCoBroadcastInviteSignalProvider =
    NotifierProvider<LiveCoBroadcastInviteSignalNotifier, int>(
  LiveCoBroadcastInviteSignalNotifier.new,
);
