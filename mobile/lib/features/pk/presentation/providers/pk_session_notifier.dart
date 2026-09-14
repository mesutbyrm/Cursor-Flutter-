import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/presentation/providers/live_video_pk_provider.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../data/pk_battle_bridge.dart';
import '../../data/pk_exception.dart';
import '../../data/pk_models.dart';
import 'pk_providers.dart';

enum PkContextKind { live, voice }

class PkSessionArgs {
  const PkSessionArgs({required this.contextId, required this.kind});

  final String contextId;
  final PkContextKind kind;
}

class PkSessionState {
  const PkSessionState({
    this.battle,
    this.candidates = const [],
    this.selfBusy = false,
    this.loading = false,
    this.error,
    this.inviteRemaining,
    this.battleRemaining,
    this.rateLimitUntil,
  });

  final PkBattle? battle;
  final List<PkCandidate> candidates;
  final bool selfBusy;
  final bool loading;
  final String? error;
  final Duration? inviteRemaining;
  final Duration? battleRemaining;
  final DateTime? rateLimitUntil;

  bool get isRateLimited =>
      rateLimitUntil != null && DateTime.now().isBefore(rateLimitUntil!);

  PkSessionState copyWith({
    PkBattle? battle,
    bool clearBattle = false,
    List<PkCandidate>? candidates,
    bool? selfBusy,
    bool? loading,
    String? error,
    bool clearError = false,
    Duration? inviteRemaining,
    Duration? battleRemaining,
    DateTime? rateLimitUntil,
    bool clearRateLimit = false,
  }) {
    return PkSessionState(
      battle: clearBattle ? null : (battle ?? this.battle),
      candidates: candidates ?? this.candidates,
      selfBusy: selfBusy ?? this.selfBusy,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      inviteRemaining: inviteRemaining ?? this.inviteRemaining,
      battleRemaining: battleRemaining ?? this.battleRemaining,
      rateLimitUntil:
          clearRateLimit ? null : (rateLimitUntil ?? this.rateLimitUntil),
    );
  }
}

class PkSessionNotifier
    extends AutoDisposeFamilyNotifier<PkSessionState, PkSessionArgs> {
  Timer? _tick;

  @override
  PkSessionState build(PkSessionArgs arg) {
    ref.onDispose(() => _tick?.cancel());
    Future.microtask(loadState);
    _startTicker();
    return const PkSessionState();
  }

  PkService get _api => ref.read(pkServiceProvider);

  void _startTicker() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final b = state.battle;
      if (b == null) return;
      final skew = _api.clockSkew;
      final invite = b.status == PkStatus.pending
          ? b.remainingInvite(skew)
          : null;
      final battleRem = b.status == PkStatus.active ||
              b.status == PkStatus.paused
          ? b.remainingBattle(skew)
          : null;
      state = state.copyWith(
        inviteRemaining: invite,
        battleRemaining: battleRem,
      );
      if (invite != null && invite.inSeconds <= 0 && b.status == PkStatus.pending) {
        unawaited(loadState());
      }
    });
  }

  Future<void> loadState() async {
    final id = arg.contextId.trim();
    if (id.isEmpty) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final battle = await _api.getState(id);
      _applyBattle(battle);
      state = state.copyWith(loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is PkException ? e.message : '$e',
      );
    }
  }

  Future<void> loadCandidates() async {
    final id = arg.contextId.trim();
    if (id.isEmpty) return;
    try {
      final bundle = arg.kind == PkContextKind.live
          ? await _api.streamCandidates(id)
          : await _api.roomCandidates(id);
      state = state.copyWith(
        candidates: bundle.candidates,
        selfBusy: bundle.selfBusy,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e is PkException ? e.message : '$e',
      );
    }
  }

  void ingestFromSse(Map<String, dynamic> payload) {
    try {
      final battle = PkBattle.fromJson(payload);
      if (battle.id.isEmpty) {
        unawaited(loadState());
        return;
      }
      _applyBattle(battle);
    } catch (_) {
      unawaited(loadState());
    }
  }

  void _applyBattle(PkBattle? battle) {
    if (battle == null || battle.id.isEmpty) {
      state = state.copyWith(clearBattle: true);
      if (arg.kind == PkContextKind.live) {
        ref.read(liveVideoPkProvider(arg.contextId).notifier).refresh();
      } else {
        ref.read(pkBattleRemoteProvider.notifier).clear();
      }
      return;
    }
    final skew = _api.clockSkew;
    state = state.copyWith(
      battle: battle,
      inviteRemaining: battle.status == PkStatus.pending
          ? battle.remainingInvite(skew)
          : null,
      battleRemaining: battle.status == PkStatus.active ||
              battle.status == PkStatus.paused
          ? battle.remainingBattle(skew)
          : null,
      clearError: true,
    );
    final remote = pkBattleToRemote(battle);
    if (arg.kind == PkContextKind.live) {
      ref.read(liveVideoPkProvider(arg.contextId).notifier).applyRemoteBattle(
            pkBattleToLiveMap(battle, myContextId: arg.contextId),
          );
    } else {
      ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(remote);
    }
  }

  Future<void> create(String targetContextId, {int durationSeconds = 180}) async {
    if (state.isRateLimited) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final battle = await _api.create(
        roomId: arg.contextId,
        targetRoomId: targetContextId,
        durationSeconds: durationSeconds,
      );
      _applyBattle(battle);
      state = state.copyWith(loading: false);
    } on PkException catch (e) {
      if (e.statusCode == 429 || e.errorCode == 'RATE_LIMITED') {
        state = state.copyWith(
          loading: false,
          rateLimitUntil: DateTime.now().add(const Duration(seconds: 30)),
          error: e.message,
        );
        return;
      }
      if (e.message.contains('PK durumu değişti')) {
        await loadState();
        return;
      }
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<void> accept() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    await _action(() => _api.accept(id));
  }

  Future<void> reject() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    await _action(() => _api.reject(id));
  }

  Future<void> cancel() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    await _action(() => _api.cancel(id));
  }

  Future<void> end() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    final status = state.battle?.status;
    if (status == PkStatus.pending) return;
    await _action(() => _api.end(id));
  }

  Future<void> _action(Future<PkBattle> Function() call) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final battle = await call();
      _applyBattle(battle);
      state = state.copyWith(loading: false);
    } on PkException catch (e) {
      if (e.message.contains('PK durumu değişti')) {
        await loadState();
        return;
      }
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }
}

final pkSessionProvider = NotifierProvider.autoDispose
    .family<PkSessionNotifier, PkSessionState, PkSessionArgs>(
  PkSessionNotifier.new,
);
