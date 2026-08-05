part of 'chat_room_providers.dart';

/// SSE aboneliği — [VoiceRoomLiveController] monolith'ten ayrıldı.
mixin VoiceRoomSseMixin on AutoDisposeFamilyNotifier<VoiceRoomLiveState, String> {

  void _startSse() {
    if (_roomKey.isEmpty) return;
    if (_sseStarted) {
      VoiceRoomDebugLog.log('sse.subscribe.skip', {'roomId': _roomKey});
      return;
    }
    _sseStarted = true;
    final storage = ref.read(tokenStorageProvider);
    final hub = ref.read(sseConnectionHubProvider);
    hub.attachVoiceRoom(_roomKey);
    final sse = hub.voiceRoom(_roomKey);
    VoiceRoomDebugLog.log('sse.subscribe', {
      'url': ChatRoomSseService.streamUrlFor(_roomKey),
      'roomId': _roomKey,
      'refs': hub.voiceRoomRefCount(_roomKey),
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
          roomId: _roomKey,
          accessToken: storage.readAccess,
          refreshTokens: () => tryRefreshAccessToken(refreshDio, storage),
          onConnected: () {
            _markSseActivity();
            GiftSyncLog.sseConnected(_roomKey);
            if (!state.sseConnected) {
              state = state.copyWith(sseConnected: true, clearError: true);
            }
            ref.read(voiceRoomGiftRealtimeProvider).setSseActive(true);
            ref.read(voiceRoomGiftSocketProvider).disconnect();
            _giftSocketStarted = false;
            if (!state.selfInRoom || !_presenceJoined) {
              unawaited(_joinPresence());
            }
            ref.read(voiceRoomDiagnosticProvider.notifier).setSse(true);
            if (!VoiceRoomBasicMode.enabled ||
                VoiceRoomBasicMode.premiumEnabled) {
              ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(false);
            }
            _notifyRealtimeIfBasic(
              VoiceRoomRealtimeKind.system,
              'Canlı bağlantı kuruldu',
            );
          },
          onDjUpdate: (payload) {
            if (payload.isNotEmpty) {
              if (VoiceRoomBasicMode.musicEnabled) {
                _applyRoomVideoPayload(payload);
              }
              unawaited(_applyDjRealtimePayload(payload));
            } else {
              unawaited(refresh(includeDj: true));
            }
          },
          onSong: (payload) {
            if (VoiceRoomBasicMode.musicEnabled) {
              _applyRoomVideoPayload(payload);
            }
            unawaited(_applyDjRealtimePayload(payload));
          },
          onSongQueue: (payload) {
            final ev = RoomSongBloc.eventFromSse(payload);
            if (ev != null) {
              ref.read(roomSongBlocProvider(_roomKey)).add(ev);
            }
          },
          onGift: (payload) {
            dispatchGiftSsePayloadRef(
              ref: ref,
              sessionKey: _roomKey,
              payload: payload,
              giftsRemote: giftsRemote,
              voiceRealtime: true,
            );
          },
          onMessage: (msg) {
            if (msg.kind == ChatMessageKind.systemJoin) {
              _pushBasicChatEvent(msg);
              return;
            }
            if (VoiceRoomBasicMode.enabled && !VoiceRoomBasicMode.premiumEnabled) {
              return;
            }
            final exists = state.messages.any((m) => m.id == msg.id);
            if (exists) return;
            state = state.copyWith(messages: [...state.messages, msg]);
            _onMusicRelatedChatMessage(msg);
            _pushBasicChatEvent(msg);
            if (msg.kind == ChatMessageKind.systemJoin &&
                VoiceOfficialJoin.isEntranceWorthy(
                  content: msg.content,
                  membership: msg.user?.membership,
                  chatRole: msg.user?.chatRole,
                ) &&
                _markEntranceOnce(msg.content)) {
              _showEnterBanner(msg.content);
            }
          },
          onPresence: (users) {
            final merged = _mergePresenceStable(users, source: 'sse');
            _detectMicChanges(merged);
            _syncPresenceJoinAnnouncements(merged);
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
            _patchHubPresenceCount(merged.length);
            if (!wasSse) _schedulePoll();
          },
          onUserJoin: _handleSseUserJoin,
          onUserLeave: _handleSseUserLeave,
          onRoomEvent: _handleRoomEvent,
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
            // PK battle — artık ayrı bir Socket.IO bağlantısı yerine
            // odanın ana SSE akışından besleniyor.
            ref.read(pkBattleProvider.notifier).applyRemoteBattle(battle);
            ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(battle);
            VoiceRoomDebugLog.log('sse.pk', {
              'roomId': _roomKey,
              'battleId': battle.id,
              'event': event,
              'status': battle.status,
            });
          },
          onSystem: _handleSseSystemEvent,
          onAnnouncement: _handleSseAnnouncement,
          onModeration: _handleSseModeration,
          onRoomUpdate: _handleSseRoomUpdate,
        );
}
