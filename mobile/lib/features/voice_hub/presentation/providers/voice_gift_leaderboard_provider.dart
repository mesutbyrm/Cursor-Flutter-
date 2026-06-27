import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../live/domain/entities/live_gift_event.dart';

/// Oturum içi hediye sıralaması — socket/poll olaylarından türetilir.
class VoiceSessionGiftLeaderboard extends Notifier<List<GiftLeaderboardEntry>> {
  final _totals = <String, _Agg>{};

  @override
  List<GiftLeaderboardEntry> build() => const [];

  void record(LiveGiftEvent event) {
    final id = event.senderId ?? event.senderName;
    final prev = _totals[id];
    _totals[id] = _Agg(
      userId: id,
      displayName: event.senderName,
      avatarUrl: prev?.avatarUrl,
      totalCoins: (prev?.totalCoins ?? 0) + event.coinCost * event.quantity,
      giftCount: (prev?.giftCount ?? 0) + event.quantity,
    );
    _publish();
  }

  void _publish() {
    final sorted = _totals.values.toList()
      ..sort((a, b) => b.totalCoins.compareTo(a.totalCoins));
    state = [
      for (var i = 0; i < sorted.length && i < 20; i++)
        GiftLeaderboardEntry(
          rank: i + 1,
          userId: sorted[i].userId,
          displayName: sorted[i].displayName,
          avatarUrl: sorted[i].avatarUrl,
          totalCoins: sorted[i].totalCoins,
          giftCount: sorted[i].giftCount,
        ),
    ];
  }

  void clear() {
    _totals.clear();
    state = const [];
  }
}

class _Agg {
  _Agg({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.totalCoins,
    required this.giftCount,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalCoins;
  final int giftCount;
}

final voiceSessionGiftLeaderboardProvider =
    NotifierProvider<VoiceSessionGiftLeaderboard, List<GiftLeaderboardEntry>>(
  VoiceSessionGiftLeaderboard.new,
);
