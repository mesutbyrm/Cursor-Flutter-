import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_gifts_remote_datasource.dart';
import 'providers/live_gift_providers.dart';
import '../providers/live_gift_leaderboard_provider.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';

/// REST hediye yanıtını SSE/poll hattıyla aynı yola sokar (animasyon, leaderboard, yayıncı kazancı).
void applyLiveGiftSendResult(
  WidgetRef ref, {
  required String streamId,
  required LiveGiftSendResult result,
  bool isHost = false,
}) {
  final ev = result.event;
  if (ev != null) {
    ref.read(liveGiftRealtimeProvider).publishRemote(ev);
    ref
        .read(giftSessionProvider(streamId).notifier)
        .onGiftSent(ev, source: 'api_response', isHost: isHost);
    ref.read(liveGiftLeaderboardProvider(streamId).notifier).record(ev);
    ref.read(liveGiftControllerProvider).ingestLocalEvent(ev);
  }
  if (result.newBalance != null) {
    ref.read(liveGiftControllerProvider).coinBalance = result.newBalance;
  }
  if (result.streamerBalance != null && isHost) {
    ref.read(liveGiftControllerProvider).streamerEarnings =
        result.streamerBalance;
  }
}
