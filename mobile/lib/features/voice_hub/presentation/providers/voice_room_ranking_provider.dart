import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gifts/presentation/sync/gift_hourly_reset.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import 'voice_room_rank_celebration_provider.dart';
import 'voice_rooms_presence_provider.dart';

/// Saatlik / günlük oda sıralama penceresi.
enum VoiceRoomRankingPeriod { hourly, daily }

/// Sıralanmış oda satırı.
class VoiceRoomRankEntry {
  const VoiceRoomRankEntry({
    required this.rank,
    required this.room,
    required this.score,
  });

  final int rank;
  final VoiceRoomEntity room;
  final int score;
}

/// SSE keşfet sayacı varsa öncelikli çevrimiçi sayı.
int resolveLiveOnlineCount(
  VoiceRoomEntity room,
  Map<String, int> livePresenceCounts,
) {
  final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final live = livePresenceCounts[key] ?? livePresenceCounts[room.id];
  if (live != null && live >= 0) return live;
  return room.displayOnline;
}

/// Üretim `ROOM_RANK` API gelene kadar: canlı oda listesinden skor proxy.
/// Skor: çevrimiçi × 10 + PK + müzik + VIP bonus (manipülasyon önleme: sunucu skoru yok).
int voiceRoomRankingScore(
  VoiceRoomEntity room, {
  int? liveOnline,
}) {
  final online = liveOnline ?? room.displayOnline;
  var score = online * 10;
  if (room.isPkLive) score += 50;
  if (room.hasMusicActivity) score += 20;
  if (room.isVip == true) score += 5;
  return score;
}

List<VoiceRoomRankEntry> buildVoiceRoomRanking(
  List<VoiceRoomEntity> rooms, {
  int limit = 100,
  Map<String, int> livePresenceCounts = const {},
}) {
  final scored = rooms
      .where((r) => r.apiRoomKey.isNotEmpty)
      .map((r) {
        final online = resolveLiveOnlineCount(r, livePresenceCounts);
        final roomForRank = online != r.displayOnline
            ? r.copyWith(onlineCount: online, userCount: online)
            : r;
        return VoiceRoomRankEntry(
          rank: 0,
          room: roomForRank,
          score: voiceRoomRankingScore(roomForRank, liveOnline: online),
        );
      })
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  final out = <VoiceRoomRankEntry>[];
  for (var i = 0; i < scored.length && i < limit; i++) {
    final e = scored[i];
    out.add(VoiceRoomRankEntry(rank: i + 1, room: e.room, score: e.score));
  }
  return out;
}

class VoiceRoomRankingState {
  const VoiceRoomRankingState({
    this.hourly = const [],
    this.daily = const [],
    this.lastUpdated,
  });

  final List<VoiceRoomRankEntry> hourly;
  final List<VoiceRoomRankEntry> daily;
  final DateTime? lastUpdated;

  VoiceRoomRankingState copyWith({
    List<VoiceRoomRankEntry>? hourly,
    List<VoiceRoomRankEntry>? daily,
    DateTime? lastUpdated,
  }) =>
      VoiceRoomRankingState(
        hourly: hourly ?? this.hourly,
        daily: daily ?? this.daily,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class VoiceRoomRankingNotifier extends Notifier<VoiceRoomRankingState> {
  void Function()? _cancelHourly;
  void Function()? _cancelDaily;

  @override
  VoiceRoomRankingState build() {
    ref.onDispose(() {
      _cancelHourly?.call();
      _cancelDaily?.call();
    });
    GiftHourlyReset.scheduleRepeating(
      () => unawaited(refresh(period: VoiceRoomRankingPeriod.hourly)),
      onCancel: (c) => _cancelHourly = c,
    );
    _scheduleDailyReset();
    Future.microtask(refresh);
    return const VoiceRoomRankingState();
  }

  void _scheduleDailyReset() {
    Timer? timer;
    void arm() {
      timer?.cancel();
      final now = DateTime.now();
      final next = DateTime(now.year, now.month, now.day + 1);
      timer = Timer(next.difference(now), () {
        unawaited(refresh(period: VoiceRoomRankingPeriod.daily));
        arm();
      });
    }

    arm();
    _cancelDaily = () => timer?.cancel();
  }

  Future<void> refresh({VoiceRoomRankingPeriod? period}) async {
    try {
      final list = await _refreshProxyRanking();
      final now = DateTime.now();
      if (period == VoiceRoomRankingPeriod.hourly) {
        state = state.copyWith(hourly: list, lastUpdated: now);
      } else if (period == VoiceRoomRankingPeriod.daily) {
        state = state.copyWith(daily: list, lastUpdated: now);
      } else {
        state = state.copyWith(hourly: list, daily: list, lastUpdated: now);
      }
      ref.read(voiceRoomRankCelebrationProvider.notifier).evaluate(state);
    } catch (_) {}
  }

  /// Üretim `GET /api/.../room-rank` geldiğinde burada remote + proxy fallback.
  Future<List<VoiceRoomRankEntry>> _refreshProxyRanking() async {
    final rooms = await ref.read(voiceRoomsProvider.future);
    final liveCounts = ref.read(voiceRoomsPresenceProvider).counts;
    return buildVoiceRoomRanking(
      rooms,
      limit: 100,
      livePresenceCounts: liveCounts,
    );
  }

  int? rankForRoom(String roomId, {VoiceRoomRankingPeriod period = VoiceRoomRankingPeriod.hourly}) {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    final list = period == VoiceRoomRankingPeriod.hourly ? state.hourly : state.daily;
    for (final e in list) {
      if (e.room.apiRoomKey == id || e.room.id == id) return e.rank;
    }
    return null;
  }
}

final voiceRoomRankingProvider =
    NotifierProvider<VoiceRoomRankingNotifier, VoiceRoomRankingState>(
  VoiceRoomRankingNotifier.new,
);
