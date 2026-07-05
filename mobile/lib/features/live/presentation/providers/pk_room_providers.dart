import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/pk/pk_match_sse_service.dart';
import '../../data/pk/pk_room_remote_datasource.dart';
import '../../domain/pk/pk_event_models.dart';
import '../../domain/pk/pk_leaderboard_models.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';

final pkRoomRemoteProvider = Provider<PkRoomRemoteDataSource>((ref) {
  return PkRoomRemoteDataSource(ref.watch(dioProvider));
});

final pkMatchSseServiceProvider = Provider<PkMatchSseService>((ref) {
  final svc = PkMatchSseService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Bir PK odasını (id) canlı takip eder — SSE birincil, 8 sn poll yedek.
class PkRoomController extends AutoDisposeFamilyNotifier<PkRoomMatch?, String> {
  Timer? _pollTimer;
  PkMatchSseService? _sse;

  @override
  PkRoomMatch? build(String matchId) {
    ref.onDispose(_dispose);
    if (matchId.isNotEmpty) _start(matchId);
    return null;
  }

  void _dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    unawaited(_sse?.disconnect());
    _sse = null;
  }

  void _start(String matchId) {
    _pollTimer?.cancel();
    unawaited(_tick());
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _tick());
    _connectSse(matchId);
  }

  Future<void> _connectSse(String matchId) async {
    final svc = ref.read(pkMatchSseServiceProvider);
    _sse = svc;
    final storage = ref.read(tokenStorageProvider);
    await svc.connectToMatch(
      matchId: matchId,
      accessToken: storage.readAccess,
      onEvent: _onSse,
    );
  }

  void _onSse(PkMatchSseEvent event) {
    if (event.match != null) {
      state = event.match;
      if (event.match!.isCompleted) {
        _pollTimer?.cancel();
      }
    }
    if (event.event != null && event.event!.isLive) {
      ref.read(pkActiveEventProvider(arg).notifier).adopt(event.event!);
    }
  }

  Future<void> _tick() async {
    try {
      final next = await ref.read(pkRoomRemoteProvider).getMatch(arg);
      if (next == null) return;
      state = next;
      if (next.isCompleted) _pollTimer?.cancel();
    } catch (_) {}
  }

  void adopt(PkRoomMatch match) {
    state = match;
    if (!match.isCompleted) _start(match.id);
  }

  Future<void> refresh() => _tick();
}

final pkRoomProvider = AutoDisposeNotifierProviderFamily<PkRoomController,
    PkRoomMatch?, String>(PkRoomController.new);

/// Bir maçtaki aktif premium etkinlik (çarpan) — SSE + 8 sn poll yedek.
class PkActiveEventController
    extends AutoDisposeFamilyNotifier<PkMatchEvent?, String> {
  Timer? _timer;

  @override
  PkMatchEvent? build(String matchId) {
    ref.onDispose(() => _timer?.cancel());
    if (matchId.isNotEmpty) {
      _timer?.cancel();
      unawaited(_tick());
      _timer = Timer.periodic(const Duration(seconds: 8), (_) => _tick());
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

  void adopt(PkMatchEvent event) {
    if (event.isLive) state = event;
  }
}

final pkActiveEventProvider = AutoDisposeNotifierProviderFamily<
    PkActiveEventController, PkMatchEvent?, String>(PkActiveEventController.new);

/// Aktif PK banları (admin) — ham map listesi.
final pkBansProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(pkRoomRemoteProvider).bans();
});

typedef PkLeaderboardKey = ({String period, String metric});

final pkLeaderboardProvider = FutureProvider.autoDispose
    .family<List<PkLeaderboardEntry>, PkLeaderboardKey>((ref, key) {
  return ref
      .read(pkRoomRemoteProvider)
      .leaderboard(period: key.period, metric: key.metric);
});

final pkStatsProvider =
    FutureProvider.autoDispose.family<PkStats, String?>((ref, userId) {
  return ref.read(pkRoomRemoteProvider).stats(userId: userId);
});

final pkRoomHistoryProvider =
    FutureProvider.autoDispose<List<PkHistoryEntry>>((ref) {
  return ref.read(pkRoomRemoteProvider).history();
});

/// Geriye dönük alias — `pk_room_history_page` import uyumu.
final pkHistoryProvider = pkRoomHistoryProvider;

/// Bir yayına ait aktif çoklu/takım PK maçı (varsa).
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
  return null;
});

/// Bir yayına ait aktif 1v1 PK (birleşik API).
final activePk1v1Provider =
    FutureProvider.autoDispose.family<PkRoomMatch?, String>((ref, streamId) async {
  final matches = await ref.read(pkRoomRemoteProvider).active();
  return findStreamPkMatch(matches, streamId, mode: PkRoomMode.oneVsOne);
});

/// Bekleyen PK davetlerim.
final pkPendingInvitesProvider =
    FutureProvider.autoDispose<List<PkRoomMatch>>((ref) {
  return ref.read(pkRoomRemoteProvider).myInvites();
});

/// 1v1 PK daveti gönder — birleşik API; başarısızsa null (üst katman fallback).
final pkUnifiedInviteProvider = Provider<PkUnifiedInviteActions>((ref) {
  return PkUnifiedInviteActions(ref);
});

class PkUnifiedInviteActions {
  PkUnifiedInviteActions(this._ref);
  final Ref _ref;

  Future<PkRoomMatch?> inviteStream({
    required String streamId,
    required String opponentStreamId,
    int durationSeconds = 180,
  }) async {
    final api = _ref.read(pkRoomRemoteProvider);
    try {
      return await api.request(
        hostStreamId: streamId,
        opponentStreamId: opponentStreamId,
        durationSec: durationSeconds,
        mode: PkRoomMode.oneVsOne,
      );
    } catch (_) {
      return null;
    }
  }

  Future<PkRoomMatch?> respond({
    required String matchId,
    required bool accept,
  }) async {
    return _ref.read(pkRoomRemoteProvider).respond(
          matchId,
          action: accept ? 'accept' : 'reject',
        );
  }

  Future<PkRoomMatch?> end(String matchId) =>
      _ref.read(pkRoomRemoteProvider).end(matchId);

  Future<PkRoomMatch?> cancel(String matchId) =>
      _ref.read(pkRoomRemoteProvider).cancel(matchId);
}
