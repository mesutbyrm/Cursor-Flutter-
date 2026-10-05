part of 'chat_room_providers.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Production `/api/live/join-room`, `heartbeat`, `leave-room` — sesli oda P0.
extension VoiceRoomLiveLifecycle on VoiceRoomLiveController {
  static const _liveHeartbeatInterval = Duration(seconds: 10);

  Future<bool> _performLiveJoinRoom() async {
    if (_presenceApiKey.isEmpty) return false;
    final gen = ++_liveSessionGeneration;
    _liveJoinCompoundOk = false;

    final user = ref.read(authControllerProvider).valueOrNull;
    final nick = _effectiveNickname(user);
    final accessToken =
        ref.read(roomAccessTokenProvider.notifier).peek(_roomKey);

    VoiceRoomDebugLog.log('api.live.join_room', {
      'room': _presenceApiKey,
      'roomType': 'voice',
    });

    try {
      final compound = await ref.read(liveRoomRemoteProvider).joinRoom(
            roomId: _presenceApiKey,
            roomType: 'voice',
            nickname: nick,
            roomAccessToken: accessToken,
          );
      if (gen != _liveSessionGeneration || !_sessionActive) return false;
      _applyLiveJoinCompound(compound);
      _liveJoinCompoundOk = true;
      ref.read(vipUnlockedRoomsProvider.notifier).unlock(_roomKey);
      VoiceRoomDebugLog.log('api.live.join_room.ok', {
        'room': compound.room.id,
        'participants': compound.participants.length,
        'seats': compound.seats.length,
      });
      return true;
    } on Object catch (e) {
      VoiceRoomDebugLog.log('api.live.join_room.fail', {
        'room': _presenceApiKey,
        'error': e.toString(),
      });
      return false;
    }
  }

  void _applyLiveJoinCompound(LiveJoinRoomResult compound) {
    final participants = VoiceRoomLiveJoinMapper.participantsToPresence(
      compound.participants,
    );
    final seats = VoiceRoomLiveJoinMapper.seatsToSlots(compound.seats);
    final mergedPresence = participants.isNotEmpty
        ? _mergePresenceStable(participants, source: 'live_join_room')
        : state.presence;

    _knownPresenceIds
      ..clear()
      ..addAll(mergedPresence.map((p) => p.id).where((id) => id.isNotEmpty));

    final listed = _selfListedIn(mergedPresence);
    if (compound.trtc.isValid) {
      ref.read(voiceRoomDiagnosticProvider.notifier).setTrtc(
            roomId: compound.trtc.effectiveStrRoomId,
            result: 1,
          );
    }

    state = state.copyWith(
      presence: mergedPresence,
      seatSlots: seats.isNotEmpty ? seats : state.seatSlots,
      ownerId: compound.room.hostId ?? state.ownerId,
      roomTrtc: compound.trtc.isValid ? compound.trtc : state.roomTrtc,
      hubOnlineCount: compound.room.viewerCount > 0
          ? compound.room.viewerCount
          : mergedPresence.length,
      selfInRoom: _selfPresenceTracker.resolve(
        previous: state.selfInRoom,
        backendJoinAcknowledged: true,
        listedInPresence: listed,
        snapshotHasMembers: mergedPresence.isNotEmpty,
      ),
      clearError: true,
    );

    if (compound.room.viewerCount > 0) {
      _patchHubPresenceCount(compound.room.viewerCount);
    }

    if (seats.isNotEmpty) {
      _roomSessionManager?.applyServerEvent(
        eventType: 'live_join_room',
        payload: {'type': 'join_room'},
        presenceUpdate: mergedPresence,
        seatsUpdate: seats,
      );
    } else {
      _roomSessionManager?.applyServerEvent(
        eventType: 'live_join_room',
        payload: {'type': 'join_room'},
        presenceUpdate: mergedPresence,
      );
    }

    if (compound.pkStatus != null && compound.pkStatus!.isActive) {
      unawaited(
        ref.read(pkBattleRemoteProvider.notifier).loadRoomBattle(
              _roomKey,
              alternateRoomId: _musicAlternateKey,
            ),
      );
    }
  }

  void _startLiveMembershipHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(_liveHeartbeatInterval, (_) {
      if (!_sessionActive || !_presenceJoined || !state.selfInRoom) return;
      unawaited(_liveMembershipHeartbeatTick());
    });
    _startNetworkRecoveryWatch();
  }

  Future<void> _liveMembershipHeartbeatTick() async {
    if (_roomKey.isEmpty) return;
    if (_presenceHeartbeatInFlight) return;
    _presenceHeartbeatInFlight = true;
    _presenceHeartbeatCount++;
    _rememberSelfSeatIfSeated();
    try {
      VoiceEventLog.heartbeat(roomId: _roomKey);
      VoiceRoomDebugLog.log('api.live.heartbeat', {
        'room': _presenceApiKey,
        'tick': _presenceHeartbeatCount,
      });
      final result = await ref.read(liveRoomRemoteProvider).heartbeat(
            roomId: _presenceApiKey,
            roomType: 'voice',
          );
      if (result.onlineCount > 0) {
        _patchHubPresenceCount(result.onlineCount);
      }
    } catch (e) {
      VoiceRoomDebugLog.log('api.live.heartbeat.fail', {
        'error': e.toString(),
      });
      final heartbeatSeat = _currentSelfSeatIndex() ?? -1;
      try {
        await ref.read(chatRoomRemoteProvider).presenceHeartbeat(
              _presenceApiKey,
              alternateKey: _presenceAlternateKey,
              seatIndex: heartbeatSeat,
            );
      } catch (_) {
        if (_presenceJoined &&
            _sessionActive &&
            _shouldRejoinPresenceAfterHeartbeatFailure(e)) {
          _presenceJoined = false;
          unawaited(_joinPresence(rejoinAfterHeartbeat: true));
        }
      }
    } finally {
      final last = _lastSseEventAt;
      final sseSilent = last == null ||
          DateTime.now().difference(last) > const Duration(seconds: 45);
      if (!state.sseConnected) {
        unawaited(_preloadPresenceMembers());
      } else if (sseSilent) {
        unawaited(resyncAfterSseReconnect());
      }
      _presenceHeartbeatInFlight = false;
    }
  }

  Future<void> _liveLeaveRoomBackend() async {
    if (_presenceApiKey.isEmpty) return;
    try {
      await ref.read(liveRoomRemoteProvider).leaveRoom(
            roomId: _presenceApiKey,
            roomType: 'voice',
          );
      VoiceRoomDebugLog.log('api.live.leave_room.ok', {'room': _presenceApiKey});
    } catch (e) {
      VoiceRoomDebugLog.log('api.live.leave_room.fail', {
        'room': _presenceApiKey,
        'error': e.toString(),
      });
    }
  }
}
