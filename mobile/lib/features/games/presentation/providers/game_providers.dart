import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/game_remote_datasource.dart';
import '../../domain/game_models.dart';
import '../../domain/game_move_dedupe.dart';
import '../../domain/game_room_poll.dart';
import '../../domain/game_state_parser.dart';

final gameRemoteProvider = Provider<GameRemoteDataSource>((ref) {
  return GameRemoteDataSource(ref.watch(dioProvider));
});

final gameCatalogProvider = FutureProvider<List<GameCatalogItem>>((ref) async {
  final remote = await ref.watch(gameRemoteProvider).fetchCatalog();
  if (remote.isNotEmpty) return remote;
  return GameCatalogFallback.all;
});

final gameRoomsProvider = FutureProvider<List<GameRoomItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchRooms();
});

final gameLeaderboardProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchLeaderboard();
});

final gameHistoryProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchHistory();
});

final gameMiniScoresProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchMiniScores();
});

final gameProfileScoresProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchProfileScores();
});

final gameTournamentsProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchTournaments();
});

class GameRoomController
    extends
        AutoDisposeFamilyNotifier<AsyncValue<GameRoomStateSnapshot>, String> {
  Timer? _poll;
  final _seenEventIds = <String>{};
  String? _cachedGameType;

  @override
  AsyncValue<GameRoomStateSnapshot> build(String roomId) {
    ref.onDispose(() {
      _poll?.cancel();
      _seenEventIds.clear();
      _cachedGameType = null;
    });
    Future.microtask(() => refresh());
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!gameRoomPollAllowed(WidgetsBinding.instance.lifecycleState)) {
        return;
      }
      refresh(silent: true);
    });
    return const AsyncValue.loading();
  }

  bool _acceptSnapshot(GameRoomStateSnapshot snapshot) {
    if (!GameStateParser.roomMatches(
      expectedRoomId: arg,
      raw: snapshot.raw,
      snapshotRoomId: snapshot.roomId,
    )) {
      return false;
    }

    if (!GameMoveDedupe.shouldApplySnapshot(
      raw: snapshot.raw,
      seenEventIds: _seenEventIds,
    )) {
      return false;
    }

    _cachedGameType = GameStateParser.gameType(snapshot.raw) ?? _cachedGameType;
    return true;
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    try {
      final snap = await ref.read(gameRemoteProvider).fetchRoomState(arg);
      if (!_acceptSnapshot(snap)) {
        if (!silent && state.valueOrNull == null) {
          state = AsyncValue.data(snap);
        }
        return;
      }
      state = AsyncValue.data(snap);
    } catch (e, st) {
      if (!silent || state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> reconcileOnResume() => refresh(silent: true);

  Future<void> sendMove(Map<String, dynamic> move) async {
    final previous = state.valueOrNull;
    final gameType =
        _cachedGameType ??
        GameStateParser.gameType(previous?.raw) ??
        move['gameType']?.toString();
    try {
      final snap = await ref
          .read(gameRemoteProvider)
          .sendMove(roomId: arg, move: move, gameType: gameType);
      if (_acceptSnapshot(snap)) {
        state = AsyncValue.data(snap);
      }
    } catch (e) {
      if (previous != null) {
        state = AsyncValue.data(previous);
      }
      rethrow;
    }
  }

  Future<void> sendChat(String text) async {
    await ref.read(gameRemoteProvider).sendChat(roomId: arg, text: text);
    await refresh(silent: true);
  }
}

final gameRoomControllerProvider = NotifierProvider.autoDispose
    .family<GameRoomController, AsyncValue<GameRoomStateSnapshot>, String>(
      GameRoomController.new,
    );

/// Foreground'a dönünce oyun state reconcile.
mixin GameRoomLifecycleMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  String get lifecycleRoomId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _GameRoomLifecycleObserver(
        onResume: () {
          ref
              .read(gameRoomControllerProvider(lifecycleRoomId).notifier)
              .reconcileOnResume();
        },
      );
}

class _GameRoomLifecycleObserver with WidgetsBindingObserver {
  _GameRoomLifecycleObserver({required this.onResume});

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
