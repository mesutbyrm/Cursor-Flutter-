import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/pk/pk_room_remote_datasource.dart';
import '../../domain/pk/pk_event_models.dart';
import '../../domain/pk/pk_leaderboard_models.dart';
import '../../domain/pk/pk_room_models.dart';

final pkRoomRemoteProvider = Provider<PkRoomRemoteDataSource>((ref) {
  return PkRoomRemoteDataSource(ref.watch(dioProvider));
});

/// Bir PK odasını (id) canlı takip eder — 2 sn poll.
/// SSE `/api/pk/{id}/stream` ileride eklenebilir; poll güvenilir baseline.
class PkRoomController extends AutoDisposeFamilyNotifier<PkRoomMatch?, String> {
  Timer? _timer;

  @override
  PkRoomMatch? build(String matchId) {
    ref.onDispose(() => _timer?.cancel());
    if (matchId.isNotEmpty) _start();
    return null;
  }

  void _start() {
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  Future<void> _tick() async {
    try {
      final next = await ref.read(pkRoomRemoteProvider).getMatch(arg);
      if (next == null) return;
      // Bitince bir tur daha göster, sonra poll'u yavaşlat.
      state = next;
      if (next.isCompleted) {
        _timer?.cancel();
      }
    } catch (_) {
      // sessiz — sonraki tick'te tekrar denenir
    }
  }

  /// Oda kurulduktan/başlatıldıktan sonra anında takibe al.
  void adopt(PkRoomMatch match) {
    state = match;
    if (!match.isCompleted) _start();
  }

  Future<void> refresh() => _tick();
}

final pkRoomProvider = AutoDisposeNotifierProviderFamily<PkRoomController,
    PkRoomMatch?, String>(PkRoomController.new);

/// Bir maçtaki aktif premium etkinlik (çarpan) — 2 sn poll.
class PkActiveEventController
    extends AutoDisposeFamilyNotifier<PkMatchEvent?, String> {
  Timer? _timer;

  @override
  PkMatchEvent? build(String matchId) {
    ref.onDispose(() => _timer?.cancel());
    if (matchId.isNotEmpty) {
      _timer?.cancel();
      unawaited(_tick());
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
    }
    return null;
  }

  Future<void> _tick() async {
    try {
      final list = await ref.read(pkRoomRemoteProvider).events(arg);
      PkMatchEvent? active;
      for (final e in list) {
        if (e.isLive) {
          active = e;
          break;
        }
      }
      state = active;
    } catch (_) {}
  }

  /// Etkinlik başlatıldıktan sonra anında göster.
  void adopt(PkMatchEvent event) {
    if (event.isLive) state = event;
  }
}

final pkActiveEventProvider = AutoDisposeNotifierProviderFamily<
    PkActiveEventController, PkMatchEvent?, String>(PkActiveEventController.new);

/// PK liderlik filtresi (period, metric).
typedef PkLeaderboardKey = ({String period, String metric});

final pkLeaderboardProvider = FutureProvider.autoDispose
    .family<List<PkLeaderboardEntry>, PkLeaderboardKey>((ref, key) {
  return ref
      .read(pkRoomRemoteProvider)
      .leaderboard(period: key.period, metric: key.metric);
});

/// PK istatistiklerim (userId null) veya belirli kullanıcının.
final pkStatsProvider =
    FutureProvider.autoDispose.family<PkStats, String?>((ref, userId) {
  return ref.read(pkRoomRemoteProvider).stats(userId: userId);
});

/// PK geçmişim (galibiyet/mağlubiyet/berabere).
final pkHistoryProvider =
    FutureProvider.autoDispose<List<PkHistoryEntry>>((ref) {
  return ref.read(pkRoomRemoteProvider).history();
});

/// Bir yayına ait aktif çoklu/takım PK maçı (varsa) — hafif keşif.
final activePkRoomProvider =
    FutureProvider.autoDispose.family<PkRoomMatch?, String>((ref, streamId) async {
  final matches = await ref.read(pkRoomRemoteProvider).active();
  for (final m in matches) {
    if (m.mode == PkRoomMode.oneVsOne) continue;
    if (m.hostStreamId == streamId ||
        m.seats.any((s) => s.streamId == streamId)) {
      return m;
    }
  }
  return matches.isNotEmpty ? matches.first : null;
});
