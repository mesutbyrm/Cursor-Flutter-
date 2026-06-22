import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../gifts/presentation/providers/gift_providers.dart';
import '../../domain/entities/live_gift_catalog.dart';
import '../../domain/entities/live_gift_event.dart';

class LiveGiftSender {
  const LiveGiftSender({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.giftName,
    required this.giftEmoji,
    required this.giftCount,
    required this.totalCoins,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String giftName;
  final String giftEmoji;
  final int giftCount;
  final int totalCoins;

  LiveGiftSender copyWith({
    int? giftCount,
    int? totalCoins,
    String? giftName,
    String? giftEmoji,
    String? avatarUrl,
  }) {
    return LiveGiftSender(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      giftName: giftName ?? this.giftName,
      giftEmoji: giftEmoji ?? this.giftEmoji,
      giftCount: giftCount ?? this.giftCount,
      totalCoins: totalCoins ?? this.totalCoins,
    );
  }
}

class LiveGiftLeaderboardNotifier
    extends AutoDisposeFamilyNotifier<List<LiveGiftSender>, String> {
  final _totals = <String, _Agg>{};

  @override
  List<LiveGiftSender> build(String streamId) {
    ref.onDispose(clear);
    return const [];
  }

  Future<void> loadInitial() async {
    final streamId = arg;
    if (streamId.isEmpty) return;
    try {
      final entries =
          await ref.read(giftRepositoryProvider).fetchLeaderboard(streamId);
      setInitialFromApi(entries);
    } catch (_) {}
  }

  void setInitialFromApi(List<GiftLeaderboardEntry> entries) {
    _totals.clear();
    for (final e in entries) {
      final id = e.userId ?? e.displayName;
      if (id.isEmpty) continue;
      _totals[id] = _Agg(
        userId: id,
        displayName: e.displayName,
        avatarUrl: e.avatarUrl,
        totalCoins: e.totalCoins,
        giftCount: e.giftCount > 0 ? e.giftCount : 1,
        giftName: 'Hediye',
        giftEmoji: '🎁',
      );
    }
    _publish();
  }

  void record(LiveGiftEvent event) {
    final id = event.senderId ?? event.senderName;
    if (id.isEmpty) return;
    final coins = event.coinCost * event.quantity;
    final emoji = LiveGiftCatalog.emojiById[event.giftId] ?? '🎁';
    final prev = _totals[id];
    _totals[id] = _Agg(
      userId: id,
      displayName: event.senderName,
      avatarUrl: prev?.avatarUrl,
      totalCoins: (prev?.totalCoins ?? 0) + coins,
      giftCount: (prev?.giftCount ?? 0) + event.quantity,
      giftName: event.giftName,
      giftEmoji: emoji,
    );
    _publish();
  }

  void _publish() {
    final sorted = _totals.values.toList()
      ..sort((a, b) => b.totalCoins.compareTo(a.totalCoins));
    state = [
      for (final row in sorted.take(20))
        LiveGiftSender(
          userId: row.userId,
          username: row.displayName,
          avatarUrl: row.avatarUrl,
          giftName: row.giftName,
          giftEmoji: row.giftEmoji,
          giftCount: row.giftCount,
          totalCoins: row.totalCoins,
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
    required this.giftName,
    required this.giftEmoji,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalCoins;
  final int giftCount;
  final String giftName;
  final String giftEmoji;
}

final liveGiftLeaderboardProvider = NotifierProvider.autoDispose
    .family<LiveGiftLeaderboardNotifier, List<LiveGiftSender>, String>(
  LiveGiftLeaderboardNotifier.new,
);
