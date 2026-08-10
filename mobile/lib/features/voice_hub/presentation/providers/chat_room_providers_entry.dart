part of 'chat_room_providers.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Oda girişi, bootstrap ve ilk yükleme — [VoiceRoomLiveController]'dan ayrıldı.
extension VoiceRoomEntryControls on VoiceRoomLiveController {
  /// Odaya giriş — sıra: presence join → GET state → GET seats → SSE → UI.
  /// TRTC sayfa tarafında `backendSyncReady` + `roomTrtc` ile bağlanır.
  Future<void> _beginRoomSession() async {
    if (_entryBegun) return;
    _entryBegun = true;
    _autoSeatAttempted = false;
    _sseStarted = false;
    _sessionActive = true;
    registerVoiceRoomLiveSession(ref, _roomKey);
    VoiceEventLog.joinStart(roomId: _roomKey);
    ref.read(voiceSessionPhaseProvider.notifier).transitionTo(
          VoiceSessionPhase.joining,
        );
    ref
        .read(voiceRoomMusicSessionProvider.notifier)
        .prepareForRoomEntry(_roomMeta);
    unawaited(VoiceRoomMusicAudioSession.ensureConfigured());
    state = state.copyWith(
      loading: true,
      presence: const [],
      seatSlots: const [],
      clearOwnerId: true,
      clearRoomTrtc: true,
      backendSyncReady: false,
    );
    _seedOptimisticSelfPresence();

    try {
      await _joinPresence();
      unawaited(_tryAutoPrivilegedSeat());
      _startSse();
      _schedulePoll(sseConnected: false);

      await _loadBackendSnapshot();
      await Future.wait<void>([
        _loadInitialMessages(),
        _preloadPkStatus(),
        _preloadGiftCatalog(),
      ], eagerError: false);
      await _bootstrapRoomData();
      VoiceEventLog.joinSuccess(
        roomId: _roomKey,
        presenceCount: state.presence.length,
      );
      ref.read(voiceSessionPhaseProvider.notifier).transitionTo(
            VoiceSessionPhase.connected,
          );
    } catch (e) {
      VoiceEventLog.error('join', e);
      ref.read(voiceSessionPhaseProvider.notifier).transitionTo(
            VoiceSessionPhase.error,
          );
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _parallelEntryLoad({bool skipPresence = false}) async {
    if (_roomKey.isEmpty) return;
    try {
      if (!skipPresence) {
        await _joinPresence();
      }
      await Future.wait<void>([
        _loadInitialMessages(),
        _preloadPkStatus(),
        _preloadGiftCatalog(),
      ], eagerError: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _preloadPkStatus() async {
    try {
      await ref.read(pkBattleRemoteProvider.notifier).loadRoomBattle(
            _roomKey,
            alternateRoomId: _musicAlternateKey,
          );
    } catch (_) {}
  }

  Future<void> _preloadGiftCatalog() async {
    try {
      if (ref.read(allGiftCatalogByIdProvider).isNotEmpty) return;
      final voiceCached = ref.read(voiceRoomGiftCatalogProvider).valueOrNull;
      if (voiceCached != null && voiceCached.isNotEmpty) return;
      final liveCached = ref.read(liveStreamGiftCatalogProvider).valueOrNull;
      if (liveCached != null && liveCached.isNotEmpty) return;
      await ref.read(chatRoomGiftsRemoteProvider).fetchGiftTypes();
    } catch (_) {}
  }

  Future<void> _preloadPresenceMembers() async {
    try {
      final members = await ref
          .read(chatRoomRemoteProvider)
          .fetchPresence(_roomKey, alternateKey: _musicAlternateKey);
      if (members.isEmpty) return;
      state = state.copyWith(
        presence: _mergePresenceStable(members, source: 'preload'),
      );
      _patchHubPresenceCount(members.length);
    } catch (_) {}
  }

  void _seedOptimisticSelfPresence() {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || _roomKey.isEmpty) return;
    if (state.presence.any((p) => p.id == user.id)) {
      state = state.copyWith(selfInRoom: true, loading: false);
      return;
    }
    final self = ChatRoomPresence(
      id: user.id,
      name: user.display,
      nickname: user.username,
      image: user.avatarUrl,
      chatRole: user.role ?? 'listener',
      roleSymbol: _roleSymbolForUser(user),
    );
    final merged = [...state.presence, self];
    state = state.copyWith(
      presence: merged,
      selfInRoom: true,
      loading: false,
    );
  }

  Future<void> _loadInitialMessages() async {
    if (_roomKey.isEmpty) return;
    try {
      final bundle =
          await ref.read(chatRoomRemoteProvider).fetchMessages(_roomKey);
      state = state.copyWith(
        messages: _filterClearedMessages(
          _mergeMessages(state.messages, bundle.messages),
        ),
        serverPermissions: bundle.myPermissions ?? state.serverPermissions,
        myNickname: bundle.myNickname ?? state.myNickname,
        roomMuted: bundle.roomMuted ?? state.roomMuted,
        loading: false,
      );
      _entrancesArmed = true;
    } catch (_) {}
  }

  Future<void> _bootstrapRoomData() async {
    unawaited(_loadBannedWords());
    unawaited(
      _warmBackgrounds().catchError((_) {
        state = state.copyWith(loading: false);
      }),
    );

    final includeDj = VoiceRoomBasicMode.enabled
        ? VoiceRoomBasicMode.musicEnabled
        : true;
    if (state.backendSyncReady) {
      if (includeDj && VoiceRoomBasicMode.musicEnabled) {
        unawaited(refresh(includeDj: true, skipPresenceAndMessages: true));
      }
    } else {
      try {
        await refresh(includeDj: includeDj);
      } catch (_) {}
    }

    if (VoiceRoomBasicMode.enabled) {
      if (VoiceRoomBasicMode.musicEnabled) {
        final player = ref.read(voiceRoomDjPlayerProvider);
        player.onTrackComplete = () => unawaited(_onDjTrackComplete());
        _wireMusicControls();
      }
      unawaited(_loadGiftLeaderboard());
      return;
    }

    final player = ref.read(voiceRoomDjPlayerProvider);
    player.onTrackComplete = () => unawaited(_onDjTrackComplete());
    _wireMusicControls();
    unawaited(_loadGiftLeaderboard());
  }
}
