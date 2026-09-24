import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../voice_hub/presentation/providers/chat_room_providers.dart';
import '../../../live/presentation/providers/live_pk_streams_provider.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live/domain/pk/pk_action_error.dart';
import '../../../live/presentation/providers/live_video_pk_provider.dart';
import '../../../voice_hub/domain/pk/pk_opponent_room_filter.dart';
import '../../../voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../data/pk_battle_bridge.dart';
import '../../data/pk_exception.dart';
import '../../data/pk_models.dart';
import '../../data/pk_service.dart';
import '../../../../../../features/voice_hub/presentation/coordinators/room_session_manager.dart';
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
  KeepAliveLink? _liveLink;
  bool _disposed = false;
  StreamSubscription<RoomSessionEvent>? _roomSessionEventSub;

  @override
  PkSessionState build(PkSessionArgs arg) {
    ref.onDispose(() {
      _disposed = true;
      _tick?.cancel();
      _releaseLive();
      _roomSessionEventSub?.cancel();
    });
    Future.microtask(() => loadState(showLoading: false));
    _startTicker();

    // Sesli oda context'te room session events'i dinle
    if (arg.kind == PkContextKind.voice) {
      _subscribeToRoomSessionEvents(arg.contextId);
    }

    return const PkSessionState();
  }

  /// Süren bir maç varken provider'ı canlı tutar.
  ///
  /// Bu provider `autoDispose`: izleyici kalmadığı an state imha olur ve
  /// sonraki okuma `const PkSessionState()` (battle **yok**) döner. Navigasyon
  /// ya da sheet/dialog açılışı izleyicileri bir kare için düşürürse PK state
  /// sıfırlanıyordu. Maç bitince link bırakılır — aksi halde sızıntı olur.
  void _retainLive() {
    _liveLink ??= ref.keepAlive();
  }

  void _releaseLive() {
    final link = _liveLink;
    _liveLink = null;
    link?.close();
  }

  PkService get _api => ref.read(pkServiceProvider);

  /// Sesli oda PK context'te room session events'ini dinle.
  /// State transition veya error'lar PK match state'ine etki edebilir.
  void _subscribeToRoomSessionEvents(String roomId) {
    final chatRoomNotifier = ref.read(voiceRoomLiveProvider(roomId).notifier);
    final manager = chatRoomNotifier.roomSessionManager;
    if (manager == null) return;

    _roomSessionEventSub = manager.events.listen((event) {
      if (_disposed) return;
      if (event is RoomSessionStateChanged) {
        // State transition — PK invite/battle validity check
        _validatePkStateForRoomSession(event.current);
      } else if (event is RoomPresenceUpdated) {
        // Presence değişti — opponent user presence'ı check et
        _validatePkOpponentPresence();
      }
    });
  }

  /// Room session state değişince PK state'ini doğrula.
  /// Örn: leaving state'e girince pending PK iptal edilmeli.
  void _validatePkStateForRoomSession(RoomSessionState roomState) {
    final battle = state.battle;
    if (battle == null || battle.id.isEmpty) return;

    // Oda leaving/idle'a girince aktif PK iptal et
    if ((roomState == RoomSessionState.leaving ||
         roomState == RoomSessionState.idle) &&
        (battle.status == PkStatus.pending ||
         battle.status == PkStatus.active)) {
      state = state.copyWith(clearBattle: true);
      _releaseLive();
    }
    // Reconnecting state — PK timing'e dikkat et
    else if (roomState == RoomSessionState.reconnecting &&
             battle.status == PkStatus.active) {
      // SSE disconnect sırasında battle state refresh edeceğiz
      Future.microtask(() => loadState());
    }
  }

  /// Opponent user presence check — PK match sırasında opponent oda'dan çıktıysa
  /// battle state'i invalidate et.
  void _validatePkOpponentPresence() {
    final battle = state.battle;
    if (battle == null ||
        battle.id.isEmpty ||
        battle.status != PkStatus.active) {
      return;
    }

    final chatRoomNotifier = ref.read(voiceRoomLiveProvider(arg.contextId).notifier);
    final manager = chatRoomNotifier.roomSessionManager;
    if (manager == null) return;

    // Opponent user presence'ını check et
    final opponentUserId = battle.user2Id;
    final opponentPresent = manager.presence
        .any((p) => p.id == opponentUserId);

    if (!opponentPresent && battle.status == PkStatus.active) {
      // Opponent oda'dan çıktı — state refresh et
      Future.microtask(() => loadState());
    }
  }

  /// Voice room PK daveti öncesi room session state'i check et.
  /// Oda joined state'de değilse invite gönderilemez.
  bool _isVoiceRoomReadyForPk() {
    if (arg.kind != PkContextKind.voice) return true;

    final chatRoomNotifier = ref.read(voiceRoomLiveProvider(arg.contextId).notifier);
    final manager = chatRoomNotifier.roomSessionManager;
    if (manager == null) return true; // Manager yok — fallback izin ver

    return manager.state == RoomSessionState.joined;
  }

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

  Future<void> loadState({bool showLoading = true}) async {
    final id = arg.contextId.trim();
    if (id.isEmpty) return;
    if (showLoading) {
      state = state.copyWith(loading: true, clearError: true);
    }
    try {
      if (arg.kind == PkContextKind.voice) {
        final api = ref.read(pkBattleRemoteDataSourceProvider);
        final hostRoom = ref.read(voiceRoomByIdProvider(id)).valueOrNull;
        final hostAlt = hostRoom != null &&
                hostRoom.slug.isNotEmpty &&
                hostRoom.slug != id
            ? hostRoom.slug
            : null;
        var remote = await api.fetchRoomBattle(
          id,
          alternateRoomId: hostAlt,
        );
        remote ??= await _firstVoiceInviteForRoom(
          api,
          id,
          alternateRoomId: hostAlt,
        );
        if (_disposed) return;
        _applyBattle(remote != null ? pkRemoteToBattle(remote) : null);
        state = state.copyWith(loading: false, clearError: true);
        return;
      }
      final battle = await _api.getState(id);
      if (_disposed) return;
      _applyBattle(battle);
      state = state.copyWith(loading: false, clearError: true);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        loading: false,
        error: e is PkException ? e.message : ApiException.userMessage(e),
      );
    }
  }

  Future<void> loadCandidates() async {
    final id = arg.contextId.trim();
    if (id.isEmpty) return;
    final userId = ref.read(authControllerProvider).valueOrNull?.id ?? '';
    PkEventLog.log('pk_load_candidates', {
      'contextId': id,
      'kind': arg.kind.name,
      'userId': userId,
    });
    try {
      String? hostAlt;
      if (arg.kind == PkContextKind.voice) {
        final hostRoom = ref.read(voiceRoomByIdProvider(id)).valueOrNull;
        if (hostRoom != null &&
            hostRoom.slug.isNotEmpty &&
            hostRoom.slug != id) {
          hostAlt = hostRoom.slug;
        }
      }
      final bundle = arg.kind == PkContextKind.live
          ? await _api.streamCandidates(id)
          : await _api.roomCandidates(id, alternateRoomId: hostAlt);
      if (_disposed) return;
      var candidates = bundle.candidates
          .where((c) => c.contextId.trim().isNotEmpty && c.contextId != id)
          .toList();
      if (candidates.isEmpty && arg.kind == PkContextKind.live) {
        await ref
            .read(livePkStreamsProvider.notifier)
            .refresh(silent: true, myStreamId: id);
        final streams = ref
            .read(livePkStreamsProvider.notifier)
            .opponentsFor(id);
        candidates = streams
            .map(
              (s) => PkCandidate(
                contextId: s.id,
                userId: s.hostUserId ?? '',
                name: s.streamerName ?? s.title,
                image: s.thumbnailUrl ?? '',
                title: s.title,
                viewers: s.viewerCount,
              ),
            )
            .where((c) => c.contextId.trim().isNotEmpty)
            .toList();
        PkEventLog.log('pk_candidates_fallback_streams', {
          'count': candidates.length,
        });
      }
      if (candidates.isEmpty && arg.kind == PkContextKind.voice) {
        try {
          await ref.read(voiceRoomsListNotifierProvider.notifier).refresh();
        } catch (_) {}
        final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? [];
        final others = filterPkEligibleOpponentRooms(
          rooms,
          excludeRoomKey: id,
        );
        candidates = others
            .map(
              (r) => PkCandidate(
                contextId:
                    r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id,
                userId: r.ownerId ?? '',
                name: r.displayTitle,
                image: '',
                title: r.displayTitle,
                viewers: r.displayOnline,
              ),
            )
            .where((c) => c.contextId.trim().isNotEmpty)
            .toList();
        PkEventLog.log('pk_candidates_fallback_voice_rooms', {
          'count': candidates.length,
        });
      }
      PkEventLog.log('pk_eligible_hosts', {
        'count': candidates.length,
        'selfBusy': bundle.selfBusy,
      });
      state = state.copyWith(
        candidates: candidates,
        selfBusy: bundle.selfBusy,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      PkEventLog.error('load_candidates', e);
      if (_disposed) return;
      state = state.copyWith(
        error: e is PkException ? e.message : ApiException.userMessage(e),
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
      _releaseLive();
      state = state.copyWith(clearBattle: true);
      if (arg.kind == PkContextKind.live) {
        ref.read(liveVideoPkProvider(arg.contextId).notifier).refresh();
      } else {
        ref.read(pkBattleRemoteProvider.notifier).clear();
      }
      return;
    }
    if (battle.status.isTerminal) {
      _releaseLive();
    } else {
      _retainLive();
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

  Future<void> create(
    String targetContextId, {
    int durationSeconds = 180,
    String? targetUserId,
  }) async {
    if (state.isRateLimited) return;
    final target = targetContextId.trim();
    if (target.isEmpty) {
      state = state.copyWith(error: 'Rakip oda seçilmesi gerekli');
      return;
    }
    final pending = state.battle;
    if (pending != null &&
        pending.status == PkStatus.pending &&
        (pending.room2Id == target || pending.user2Id == target)) {
      state = state.copyWith(
        error: 'Bu yayıncıya zaten PK daveti gönderildi',
      );
      return;
    }
    if (state.selfBusy ||
        (pending != null && pending.status.isLive && pending.id.isNotEmpty)) {
      state = state.copyWith(error: 'Zaten aktif veya bekleyen bir PK var');
      return;
    }
    PkEventLog.requestStart(
      streamId: arg.kind == PkContextKind.live ? arg.contextId : null,
      roomId: arg.kind == PkContextKind.voice ? arg.contextId : null,
      targetId: target,
    );
    state = state.copyWith(loading: true, clearError: true);

    // Sesli oda PK daveti kılavuz §9.3 `POST /api/chat/rooms/{roomId}/pk`
    // üzerinden gider — alıcı da bu ucu (ve /api/pk/me/invites) pollar. Canlı
    // yayın PK'sı ayrı uçta kalır (aşağıdaki _api.create).
    if (arg.kind == PkContextKind.voice) {
      await _createVoiceInvite(
        target,
        durationSeconds: durationSeconds,
        targetUserId: targetUserId,
      );
      return;
    }

    try {
      final battle = await _api.create(
        roomId: arg.contextId,
        targetRoomId: target,
        durationSeconds: durationSeconds,
      );
      if (_disposed) return;
      _applyBattle(battle);
      state = state.copyWith(loading: false);
    } on PkException catch (e) {
      if (_disposed) return;
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
      if (_disposed) return;
      state = state.copyWith(loading: false, error: ApiException.userMessage(e));
    }
  }

  /// Sesli oda daveti — chat-room PK ucu (kılavuz §9.3). Dönen `PkBattleRemote`
  /// hem `pkBattleRemoteProvider`'a işlenir (inviteRoom içinde) hem de sheet'in
  /// `PkBattle` state'ine köprülenir ki "İSTEK GÖNDERİLDİ" paneli görünsün.
  ///
  /// Oda joined state'de değilse invite gönderilemez (RoomSessionManager check).
  Future<void> _createVoiceInvite(
    String targetRoomId, {
    required int durationSeconds,
    String? targetUserId,
  }) async {
    // Room session state check — RoomSessionManager entegrasyonu
    if (!_isVoiceRoomReadyForPk()) {
      state = state.copyWith(
        loading: false,
        error: 'Oda henüz hazır değil, lütfen bekleyin',
      );
      return;
    }

    try {
      final hostRoom =
          ref.read(voiceRoomByIdProvider(arg.contextId)).valueOrNull;
      final hostAlt = hostRoom != null &&
              hostRoom.slug.isNotEmpty &&
              hostRoom.slug != arg.contextId
          ? hostRoom.slug
          : null;
      final remote = await ref.read(pkBattleRemoteProvider.notifier).inviteRoom(
            roomId: arg.contextId,
            alternateRoomId: hostAlt,
            opponentRoomId: targetRoomId,
            guestUserId: targetUserId?.trim() ?? '',
            durationSeconds: durationSeconds,
          );
      if (_disposed) return;
      if (remote == null || remote.effectiveId.isEmpty) {
        state = state.copyWith(
          loading: false,
          error: 'PK daveti gönderilemedi, tekrar deneyin',
        );
        return;
      }
      final battle = pkRemoteToBattle(remote);
      if (battle.status.isTerminal) {
        _releaseLive();
      } else {
        _retainLive();
      }
      state = state.copyWith(battle: battle, loading: false, clearError: true);
    } on ApiException catch (e) {
      if (_disposed) return;
      if (e.statusCode == 429) {
        state = state.copyWith(
          loading: false,
          rateLimitUntil: DateTime.now().add(const Duration(seconds: 30)),
          error: 'Çok fazla istek — lütfen biraz bekleyin',
        );
        return;
      }
      state = state.copyWith(
        loading: false,
        error: ApiException.userMessage(e),
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(loading: false, error: ApiException.userMessage(e));
    }
  }

  Future<void> accept() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    if (arg.kind == PkContextKind.voice) {
      await _voicePkAction(
        () => ref.read(pkBattleRemoteProvider.notifier).accept(
              id,
              roomId: arg.contextId,
            ),
      );
      return;
    }
    await _action(() => _api.accept(id));
  }

  Future<void> reject() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    if (arg.kind == PkContextKind.voice) {
      await _voicePkAction(
        () => ref.read(pkBattleRemoteProvider.notifier).reject(
              id,
              roomId: arg.contextId,
            ),
      );
      return;
    }
    await _action(() => _api.reject(id));
  }

  Future<void> cancel() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    if (arg.kind == PkContextKind.voice) {
      await _voicePkAction(
        () => ref.read(pkBattleRemoteProvider.notifier).cancel(
              id,
              roomId: arg.contextId,
            ),
      );
      return;
    }
    await _action(() => _api.cancel(id));
  }

  Future<void> end() async {
    final id = state.battle?.id;
    if (id == null || id.isEmpty) return;
    final status = state.battle?.status;
    if (status == PkStatus.pending) return;
    if (arg.kind == PkContextKind.voice) {
      await _voicePkAction(
        () => ref.read(pkBattleRemoteProvider.notifier).end(
              id,
              roomId: arg.contextId,
            ),
      );
      return;
    }
    await _action(() => _api.end(id));
  }

  Future<PkBattleRemote?> _firstVoiceInviteForRoom(
    PkBattleRemoteDataSource api,
    String roomKey, {
    String? alternateRoomId,
  }) async {
    final keys = <String>{
      roomKey.trim(),
      if (alternateRoomId != null && alternateRoomId.trim().isNotEmpty)
        alternateRoomId.trim(),
    };
    bool matchesRoom(String? raw) {
      final v = raw?.trim() ?? '';
      if (v.isEmpty) return false;
      for (final k in keys) {
        if (k == v || k.endsWith(v) || v.endsWith(k)) return true;
      }
      return false;
    }

    final invites = await api.fetchMyInvites();
    for (final inv in invites) {
      if (!inv.isPending) continue;
      if (matchesRoom(inv.opponentVoiceRoomId)) return inv;
      if (matchesRoom(inv.voiceRoomId)) return inv;
    }
    return null;
  }

  Future<void> _voicePkAction(
    Future<PkBattleRemote?> Function() call,
  ) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final remote = await call();
      if (_disposed) return;
      if (remote != null) {
        _applyBattle(pkRemoteToBattle(remote));
      } else {
        await loadState();
      }
      state = state.copyWith(loading: false);
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        loading: false,
        error: ApiException.userMessage(e),
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(loading: false, error: ApiException.userMessage(e));
    }
  }

  Future<void> _action(Future<PkBattle> Function() call) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final battle = await call();
      if (_disposed) return;
      _applyBattle(battle);
      state = state.copyWith(loading: false);
    } on PkException catch (e) {
      if (_disposed) return;
      // Sunucu istenen sonucu zaten uygulamışsa (süre dolunca maçı kendisi
      // bitirir) bu bir hata değil; sessizce senkron ol.
      if (pkActionErrorMeansAlreadySettled(e.message)) {
        await loadState();
        return;
      }
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      if (_disposed) return;
      if (pkActionErrorMeansAlreadySettled(e)) {
        await loadState();
        return;
      }
      state = state.copyWith(loading: false, error: ApiException.userMessage(e));
    }
  }
}

final pkSessionProvider = NotifierProvider.autoDispose
    .family<PkSessionNotifier, PkSessionState, PkSessionArgs>(
  PkSessionNotifier.new,
);
