import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_room_ranking_provider.dart';

/// Top 3 oda sıralama değişimi — global bildirim tetikleyicisi.
class VoiceRoomRankCelebration {
  const VoiceRoomRankCelebration({
    required this.rank,
    required this.roomName,
    required this.period,
    required this.seq,
  });

  final int rank;
  final String roomName;
  final VoiceRoomRankingPeriod period;
  final int seq;
}

class VoiceRoomRankCelebrationNotifier
    extends Notifier<VoiceRoomRankCelebration?> {
  final Map<String, int> _lastTopRanks = {};
  final Map<String, DateTime> _cooldownUntil = {};
  static const _cooldown = Duration(seconds: 90);

  @override
  VoiceRoomRankCelebration? build() => null;

  void evaluate(VoiceRoomRankingState ranking) {
    final now = DateTime.now();
    for (final period in VoiceRoomRankingPeriod.values) {
      final list = period == VoiceRoomRankingPeriod.hourly
          ? ranking.hourly
          : ranking.daily;
      for (final entry in list.take(3)) {
        final key = '${period.name}:${entry.room.apiRoomKey}';
        final prev = _lastTopRanks[key];
        _lastTopRanks[key] = entry.rank;
        if (entry.rank > 3) continue;
        final improved = prev == null || entry.rank < prev;
        if (!improved) continue;
        final until = _cooldownUntil[key];
        if (until != null && now.isBefore(until)) continue;
        _cooldownUntil[key] = now.add(_cooldown);
        state = VoiceRoomRankCelebration(
          rank: entry.rank,
          roomName: entry.room.displayTitle,
          period: period,
          seq: (state?.seq ?? 0) + 1,
        );
        return;
      }
    }
  }

  void dismiss() => state = null;
}

final voiceRoomRankCelebrationProvider =
    NotifierProvider<VoiceRoomRankCelebrationNotifier, VoiceRoomRankCelebration?>(
  VoiceRoomRankCelebrationNotifier.new,
);
