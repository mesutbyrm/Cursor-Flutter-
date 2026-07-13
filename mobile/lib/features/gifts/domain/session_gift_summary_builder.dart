import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/data/jeton_packages_catalog.dart';
import '../../live/presentation/gifts/live_gift_controller.dart';
import '../../live/presentation/providers/live_gift_leaderboard_provider.dart';
import '../../live/presentation/providers/live_guest_grid_provider.dart';
import '../../voice_hub/presentation/providers/voice_gift_leaderboard_provider.dart';
import '../../voice_hub/presentation/providers/voice_seat_gift_totals_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import 'gift_revenue_display.dart';
import 'session_gift_summary.dart';

/// Oturum sonu hediye özeti — mevcut provider verilerinden üretilir.
abstract final class SessionGiftSummaryBuilder {
  static SessionGiftSummary forLiveBroadcast({
    required WidgetRef ref,
    required String streamId,
    required String hostUserId,
    required String hostDisplayName,
    required String? myUserId,
  }) {
    final senders = ref.read(liveGiftLeaderboardProvider(streamId));
    final totalGross =
        senders.fold<int>(0, (s, e) => s + e.totalCoins);
    final hostNet =
        ref.read(liveGiftControllerProvider).streamerEarnings ?? 0;

    var guestNet = 0;
    final grid = ref.read(liveGuestGridProvider);
    for (final slot in grid.slots) {
      if (!slot.isHost && slot.jetonEarned > 0) {
        guestNet += slot.jetonEarned;
      }
    }

    final myId = myUserId?.trim() ?? '';
    final isHost = myId.isNotEmpty && myId == hostUserId.trim();
    var myNet = isHost ? hostNet : 0;
    if (!isHost && myId.isNotEmpty) {
      for (final slot in grid.slots) {
        if (slot.userId == myId && slot.jetonEarned > 0) {
          myNet += slot.jetonEarned;
        }
      }
    }

    final rate = ref.read(walletBalancesProvider).valueOrNull?.jetonTlRate;

    return SessionGiftSummary(
      title: 'Yayın özeti',
      totalGrossJeton: totalGross,
      myNetJeton: myNet,
      guestNetJeton: guestNet,
      senders: [
        for (final s in senders)
          SessionGiftSenderRow(
            displayName: s.username,
            grossJeton: s.totalCoins,
            giftCount: s.giftCount,
          ),
      ],
      jetonTlRate: rate ?? kDefaultJetonTlRate,
      isHostOrOwner: isHost,
      recipientOnly: !isHost && myNet > 0,
    );
  }

  static SessionGiftSummary forVoiceRoom({
    required WidgetRef ref,
    required String roomTitle,
    required String? ownerUserId,
    required String? ownerDisplayName,
    required String? myUserId,
    required String? myDisplayName,
  }) {
    final senders = ref.read(voiceSessionGiftLeaderboardProvider);
    final totalGross =
        senders.fold<int>(0, (s, e) => s + e.totalCoins);

    final seatTotals = ref.read(voiceSeatGiftTotalsProvider);
    final ownerId = ownerUserId?.trim() ?? '';
    final ownerName = ownerDisplayName?.trim() ?? '';
    final myId = myUserId?.trim() ?? '';
    final myName = myDisplayName?.trim() ?? '';

    var ownerGross = 0;
    if (ownerId.isNotEmpty) {
      ownerGross = seatTotals[VoiceSeatGiftTotals.idKey(ownerId)]?.totalCoins ?? 0;
    }
    if (ownerGross == 0 && ownerName.isNotEmpty) {
      ownerGross =
          seatTotals[VoiceSeatGiftTotals.nameKey(ownerName)]?.totalCoins ?? 0;
    }

    var guestGross = 0;
    for (final entry in seatTotals.entries) {
      final agg = entry.value;
      if (ownerId.isNotEmpty && entry.key == VoiceSeatGiftTotals.idKey(ownerId)) {
        continue;
      }
      if (ownerName.isNotEmpty &&
          entry.key == VoiceSeatGiftTotals.nameKey(ownerName)) {
        continue;
      }
      guestGross += agg.totalCoins;
    }

    final ownerNet = GiftRevenueDisplay.liveBroadcasterNet(ownerGross);
    final guestNet = GiftRevenueDisplay.liveBroadcasterNet(guestGross);

    final isOwner = myId.isNotEmpty && myId == ownerId;
    var myNet = 0;
    if (isOwner) {
      myNet = ownerNet;
    } else if (myId.isNotEmpty || myName.isNotEmpty) {
      final mine = ref.read(voiceSeatGiftTotalsProvider.notifier).forReceiver(
            userId: myId.isNotEmpty ? myId : null,
            displayName: myName.isNotEmpty ? myName : null,
          );
      if (mine != null && mine.totalCoins > 0) {
        myNet = GiftRevenueDisplay.liveBroadcasterNet(mine.totalCoins);
      }
    }

    final rate = ref.read(walletBalancesProvider).valueOrNull?.jetonTlRate;

    return SessionGiftSummary(
      title: roomTitle.isNotEmpty ? '$roomTitle — özet' : 'Oda özeti',
      totalGrossJeton: totalGross,
      myNetJeton: myNet,
      guestNetJeton: guestNet,
      senders: [
        for (final s in senders)
          SessionGiftSenderRow(
            displayName: s.displayName,
            grossJeton: s.totalCoins,
            giftCount: s.giftCount,
          ),
      ],
      jetonTlRate: rate ?? kDefaultJetonTlRate,
      isHostOrOwner: isOwner,
      recipientOnly: !isOwner && myNet > 0,
    );
  }

  /// Alıcı veya yayıncı odadan çıkınca cüzdanı yenile.
  static Future<void> refreshWalletIfRecipient(WidgetRef ref, SessionGiftSummary s) async {
    if (s.myNetJeton > 0 || s.recipientOnly) {
      await ref.refreshWalletCache(force: true);
    }
  }
}
