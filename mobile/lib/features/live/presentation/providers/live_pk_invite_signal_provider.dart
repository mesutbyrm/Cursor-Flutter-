import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PK davet sinyali — socket/SSE olayı sonrası dinleyicileri uyandırır.
class LivePkInviteSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final livePkInviteSignalProvider =
    NotifierProvider<LivePkInviteSignalNotifier, int>(
  LivePkInviteSignalNotifier.new,
);
