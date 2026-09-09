import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_room_ranking_provider.dart';

/// Sıralama kutlaması tetik kaynağı.
enum RankCelebrationTrigger {
  /// İlk yükleme — kutlama gösterme.
  bootstrap,
  /// Saat başı — yalnızca o anda uygulamada olanlara.
  hourBoundary,
  /// Gün başı — yalnızca o anda uygulamada olanlara.
  dailyBoundary,
}

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
  final Set<String> _shownPeriodKeys = {};
  var _seq = 0;

  @override
  VoiceRoomRankCelebration? build() => null;

  void evaluate(
    VoiceRoomRankingState ranking, {
    RankCelebrationTrigger trigger = RankCelebrationTrigger.bootstrap,
  }) {
    if (trigger == RankCelebrationTrigger.bootstrap) return;

    final now = DateTime.now();
    final periods = trigger == RankCelebrationTrigger.dailyBoundary
        ? [VoiceRoomRankingPeriod.daily]
        : trigger == RankCelebrationTrigger.hourBoundary
            ? [VoiceRoomRankingPeriod.hourly]
            : VoiceRoomRankingPeriod.values;

    for (final period in periods) {
      final periodKey = _periodWindowKey(period, now);
      if (_shownPeriodKeys.contains(periodKey)) continue;

      final list = period == VoiceRoomRankingPeriod.hourly
          ? ranking.hourly
          : ranking.daily;
      final top = list.where((e) => e.rank >= 1 && e.rank <= 3).toList();
      if (top.isEmpty) continue;

      top.sort((a, b) => a.rank.compareTo(b.rank));
      final best = top.first;
      _shownPeriodKeys.add(periodKey);
      _seq++;
      state = VoiceRoomRankCelebration(
        rank: best.rank,
        roomName: best.room.displayTitle,
        period: period,
        seq: _seq,
      );
      return;
    }
  }

  String _periodWindowKey(VoiceRoomRankingPeriod period, DateTime now) {
    if (period == VoiceRoomRankingPeriod.daily) {
      return 'daily:${now.year}-${now.month}-${now.day}';
    }
    return 'hourly:${now.year}-${now.month}-${now.day}-${now.hour}';
  }

  void dismiss() => state = null;

  /// Oturum sıfırlama — eski sıralama state'i taşınmaz.
  void resetSession() {
    _shownPeriodKeys.clear();
    state = null;
  }
}

final voiceRoomRankCelebrationProvider =
    NotifierProvider<VoiceRoomRankCelebrationNotifier, VoiceRoomRankCelebration?>(
  VoiceRoomRankCelebrationNotifier.new,
);
