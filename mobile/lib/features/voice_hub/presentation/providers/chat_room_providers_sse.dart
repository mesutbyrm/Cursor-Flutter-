part of 'chat_room_providers.dart';

/// SSE aboneliği — [VoiceRoomLiveController] monolith'ten ayrıldı.
mixin VoiceRoomSseMixin on AutoDisposeFamilyNotifier<VoiceRoomLiveState, String> {
  VoiceRoomLiveController get _sse => this as VoiceRoomLiveController;

  void _startSse() {
    final roomKey = _sse._roomKey;
    if (roomKey.isEmpty) return;
    if (_sse._sseStarted) {
      VoiceRoomDebugLog.log('sse.subscribe.skip', {'roomId': roomKey});
      return;
    }
    _sse._sseStarted = true;
    final storage = ref.read(tokenStorageProvider);
    final hub = ref.read(sseConnectionHubProvider);
    hub.attachVoiceRoom(roomKey);
    final sse = hub.voiceRoom(roomKey);
    VoiceRoomDebugLog.log('sse.subscribe', {
      'url': ChatRoomSseService.streamUrlFor(roomKey),
      'roomId': roomKey,
      'refs': hub.voiceRoomRefCount(roomKey),
    });
    final giftsRemote = ref.read(liveGiftsRemoteProvider);
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    sse
        .connect(
          roomId: roomKey,
          accessToken: storage.readAccess,
          refreshTokens: () => tryRefreshAccessToken(refreshDio, storage),
          onConnected: () {
            _sse._markSseActivity();
            GiftSyncLog.sseConnected(roomKey);
            if (!state.sseConnected) {
              state = state.copyWith(sseConnected: true, clearError: true);
            }
            ref.read(voiceRoomGiftRealtimeProvider).setSseActive(true);
            if (!state.selfInRoom || !_sse._presenceJoined) {
              unawaited(_sse._joinPresence());
            }
            ref.read(voiceRoomDiagnosticProvider.notifier).setSse(true);
            if (!VoiceRoomBasicMode.enabled ||
                VoiceRoomBasicMode.premiumEnabled) {
              ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(false);
            }
            _sse._notifyRealtimeIfBasic(
              VoiceRoomRealtimeKind.system,
              'Canlı bağlantı kuruldu',
            );
          },
          onDjUpdate: (payload) {
            if (payload.isNotEmpty) {
              if (VoiceRoomBasicMode.musicEnabled) {
                _sse._applyRoomVideoPayload(payload);
              }
              unawaited(_sse._applyDjRealtimePayload(payload));
            } else {
              unawaited(_sse.refresh(includeDj: true));
            }
          },
          onSong: (payload) {
            if (VoiceRoomBasicMode.musicEnabled) {
              _sse._applyRoomVideoPayload(payload);
            }
            unawaited(_sse._applyDjRealtimePayload(payload));
          },
          onSongQueue: (payload) {
            final ev = RoomSongBloc.eventFromSse(payload);
            if (ev != null) {
              ref.read(roomSongBlocProvider(roomKey)).add(ev);
            }
          },
          onGift: (payload) {
            dispatchGiftSsePayloadRef(
              ref: ref,
              sessionKey: roomKey,
              payload: payload,
              giftsRemote: giftsRemote,
              voiceRealtime: true,
            );
          },
          onMessage: (msg) {
            if (msg.kind == ChatMessageKind.systemJoin) {
              _sse._pushBasicChatEvent(msg);
              return;
            }
            if (VoiceRoomBasicMode.enabled && !VoiceRoomBasicMode.premiumEnabled) {
              return;
            }
            final exists = state.messages.any((m) => m.id == msg.id);
            if (exists) return;
            state = state.copyWith(messages: [...state.messages, msg]);
            _sse._onMusicRelatedChatMessage(msg);
            _sse._pushBasicChatEvent(msg);
            if (msg.kind == ChatMessageKind.systemJoin &&
                VoiceOfficialJoin.isEntranceWorthy(
                  content: msg.content,
                  membership: msg.user?.membership,
                  chatRole: msg.user?.chatRole,
                ) &&
                _sse._markEntranceOnce(msg.content)) {
              _sse._showEnterBanner(msg.content);
            }
          },
          onPresence: (users) {
            final merged = _sse._mergePresenceStable(users, source: 'sse');
            _sse._detectMicChanges(merged);
            _sse._syncPresenceJoinAnnouncements(merged);
            final wasSse = state.sseConnected;
            state = state.copyWith(
              presence: merged,
              sseConnected: true,
              selfInRoom: true,
              clearError: true,
            );
            ref.read(voiceRoomDiagnosticProvider.notifier).setSse(true);
            ref
                .read(voiceRoomDiagnosticProvider.notifier)
                .setPresence(joined: true, count: merged.length);
            _sse._patchHubPresenceCount(merged.length);
            if (!wasSse) _sse._schedulePoll();
          },
          onUserJoin: _sse._handleSseUserJoin,
          onUserLeave: _sse._handleSseUserLeave,
          onRoomEvent: _sse._handleRoomEvent,
          onTyping: (users) {
            state = state.copyWith(typingUsers: users);
          },
          onFortuneRequest: (payload) {
            if (VoiceRoomBasicMode.enabled) return;
            final session = parsePsychicSsePayload(payload);
            if (session == null) return;
            emitPsychicLiveRequest(ref, session);
          },
          onPk: (battle, event) {
            if (VoiceRoomBasicMode.enabled && !VoiceRoomBasicMode.premiumEnabled) {
              return;
            }
            ref.read(pkBattleProvider.notifier).applyRemoteBattle(battle);
            ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(battle);
            VoiceRoomDebugLog.log('sse.pk', {
              'roomId': roomKey,
              'battleId': battle.id,
              'event': event,
              'status': battle.status,
            });
          },
          onSystem: _sse._handleSseSystemEvent,
          onAnnouncement: _sse._handleSseAnnouncement,
          onModeration: _sse._handleSseModeration,
          onRoomUpdate: _sse._handleSseRoomUpdate,
        );
  }
}
