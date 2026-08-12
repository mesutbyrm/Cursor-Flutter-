part of 'chat_room_providers.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Backend senkronizasyonu — GET /state, GET /seats, SSE `room_event`.
extension VoiceRoomBackendSync on VoiceRoomLiveController {
  /// Odaya giriş sırası: join → state → seats (SSE ve TRTC ayrı adımlarda).
  Future<void> _loadBackendSnapshot() async {
    if (_roomKey.isEmpty) return;
    VoiceRoomDebugLog.log('api.state.fetch', {'room': _roomKey});
    final remote = ref.read(chatRoomRemoteProvider);
    VoiceRoomStateSnapshot? snapshot;
    List<VoiceRoomSeatSlot> seats = const [];
    try {
      final results = await Future.wait<Object?>([
        remote
            .fetchRoomState(_roomKey, alternateKey: _musicAlternateKey)
            .then<Object?>((value) => value)
            .catchError((Object e) {
          VoiceRoomDebugLog.log('api.state.fail', {'error': e.toString()});
          return null;
        }),
        remote
            .fetchSeats(
              _roomKey,
              alternateKey: _musicAlternateKey,
              targetSeatCount: state.roomSeatCount ?? _roomMeta.seatCount,
            )
            .catchError((Object e) {
          VoiceRoomDebugLog.log('api.seats.fail', {'error': e.toString()});
          return <VoiceRoomSeatSlot>[];
        }),
      ], eagerError: false);
      snapshot = results[0] as VoiceRoomStateSnapshot?;
      seats = (results[1] as List<VoiceRoomSeatSlot>?) ?? const [];
      if (snapshot != null) {
        _applyStateSnapshot(snapshot);
        VoiceRoomDebugLog.log('api.state.ok', {
          'room': _roomKey,
          'participants': snapshot.participants.length,
          'owner': snapshot.ownerId,
        });
      }
      if (seats.isNotEmpty) {
        final nextPresence = _syncPresenceSeatIndexFromSlots(
          state.presence,
          seats,
        );
        state = state.copyWith(seatSlots: seats, presence: nextPresence);
      }
      VoiceRoomDebugLog.log('api.seats.ok', {
        'room': _roomKey,
        'count': seats.length,
      });
    } on Object catch (e) {
      VoiceRoomDebugLog.log('api.snapshot.fail', {'error': e.toString()});
    }

    state = state.copyWith(backendSyncReady: true, loading: false);
    unawaited(_tryAutoPrivilegedSeat());
  }

  void _applyStateSnapshot(VoiceRoomStateSnapshot snapshot) {
    final participants = snapshot.participants;
    _knownPresenceIds
      ..clear()
      ..addAll(participants.map((p) => p.id).where((id) => id.isNotEmpty));
    final mergedPresence = participants.isEmpty
        ? state.presence
        : _mergePresenceStable(participants, source: 'state_snapshot');
    state = state.copyWith(
      presence: mergedPresence,
      seatSlots: snapshot.seats.isNotEmpty ? snapshot.seats : state.seatSlots,
      ownerId: snapshot.ownerId,
      roomTrtc: snapshot.trtc,
      serverPermissions: snapshot.me ?? state.serverPermissions,
      selfInRoom: true,
      clearError: true,
      roomSeatCount: snapshot.seatCount ?? state.roomSeatCount,
      roomMaxUsers: snapshot.maxUsers ?? state.roomMaxUsers,
    );
    if (snapshot.onlineCount != null) {
      _patchHubPresenceCount(snapshot.onlineCount!);
    } else if (participants.isNotEmpty) {
      _patchHubPresenceCount(participants.length);
    }
    if (snapshot.trtc != null) {
      ref.read(voiceRoomDiagnosticProvider.notifier).setTrtc(
            roomId: snapshot.trtc!.effectiveStrRoomId,
            result: 1,
          );
    }
  }

  void _handleRoomEvent(Map<String, dynamic> payload) {
    _markSseActivity();
    final event = (payload['event'] ?? payload['type'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    VoiceRoomDebugLog.log('sse.room_event', {
      'room': _roomKey,
      'event': event,
    });
    switch (event) {
      case 'user_joined':
        _applyRoomEventUserJoined(payload);
        return;
      case 'user_left':
        _applyRoomEventUserLeft(payload);
        return;
      case 'mic_changed':
        _applyRoomEventMicChanged(payload);
        return;
      case 'seat_changed':
        _applyRoomEventSeatChanged(payload);
        return;
      case 'seat_update':
        _scheduleSeatsRefreshFromBackend();
        return;
      case 'owner_changed':
        _applyRoomEventOwnerChanged(payload);
        return;
      case 'room_closed':
        _applyRoomEventRoomClosed(payload);
        return;
      default:
        return;
    }
  }

  void _applyRoomEventUserJoined(Map<String, dynamic> payload) {
    final userId = payload['userId']?.toString() ?? payload['id']?.toString();
    if (userId == null || userId.isEmpty) return;
    if (state.presence.any((p) => p.id == userId)) return;
    final name = payload['name']?.toString() ??
        payload['displayName']?.toString() ??
        'Kullanıcı';
    final user = ChatRoomPresence(
      id: userId,
      name: name,
      image: payload['image']?.toString(),
      micOn: _parseEventBool(payload['micOn']),
      seatIndex: _parseEventInt(payload['seatIndex']),
    );
    final next = [...state.presence, user];
    _knownPresenceIds.add(userId);
    state = state.copyWith(presence: next, sseConnected: true);
    _patchHubPresenceCount(next.length);
    _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.join, '$name odaya katıldı');
  }

  void _applyRoomEventUserLeft(Map<String, dynamic> payload) {
    final userId = payload['userId']?.toString() ?? payload['id']?.toString();
    if (userId == null || userId.isEmpty) return;
    final name = payload['name']?.toString() ?? 'Bir kullanıcı';
    final remaining = state.presence.where((p) => p.id != userId).toList();
    if (remaining.length == state.presence.length) return;
    _knownPresenceIds.remove(userId);
    state = state.copyWith(presence: remaining);
    _patchHubPresenceCount(remaining.length);
    _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.leave, '$name çıkış yaptı');
    _clearSeatForUser(userId);
  }

  void _applyRoomEventMicChanged(Map<String, dynamic> payload) {
    final userId = payload['userId']?.toString();
    if (userId == null || userId.isEmpty) return;
    final micOn = _parseEventBool(payload['micOn']) ?? false;
    final next = state.presence.map((p) {
      if (p.id != userId) return p;
      return ChatRoomPresence(
        id: p.id,
        name: p.name,
        nickname: p.nickname,
        image: p.image,
        chatRole: p.chatRole,
        roleSymbol: p.roleSymbol,
        membership: p.membership,
        seatIndex: p.seatIndex,
        isSpeaking: micOn,
        isMuted: !micOn,
        micOn: micOn,
      );
    }).toList();
    state = state.copyWith(presence: next);
    _syncSeatMic(userId, micOn);
  }

  void _applyRoomEventSeatChanged(Map<String, dynamic> payload) {
    final userId = payload['userId']?.toString();
    if (userId == null || userId.isEmpty) return;
    final newSeat = _parseEventInt(payload['seatIndex']);
    final prevSeat = _parseEventInt(payload['previousSeatIndex']);
    final nextPresence = state.presence.map((p) {
      if (p.id != userId) return p;
      return ChatRoomPresence(
        id: p.id,
        name: p.name,
        nickname: p.nickname,
        image: p.image,
        chatRole: p.chatRole,
        roleSymbol: p.roleSymbol,
        membership: p.membership,
        seatIndex: newSeat,
        isSpeaking: p.isSpeaking,
        isMuted: p.isMuted,
        micOn: p.micOn,
      );
    }).toList();
    final nextSeats = _patchSeatSlots(
      state.seatSlots,
      userId: userId,
      newIndex: newSeat,
      previousIndex: prevSeat,
      occupantName: payload['name']?.toString(),
      occupantImage: payload['image']?.toString(),
    );
    state = state.copyWith(presence: nextPresence, seatSlots: nextSeats);
    unawaited(_tryAutoPrivilegedSeat());
  }

  void _applyRoomEventOwnerChanged(Map<String, dynamic> payload) {
    final newOwner = payload['newOwnerId']?.toString() ??
        payload['ownerId']?.toString();
    if (newOwner == null || newOwner.isEmpty) return;
    state = state.copyWith(ownerId: newOwner);
    final name = payload['newOwnerName']?.toString() ?? 'Yeni oda sahibi';
    _notifyRealtimeIfBasic(
      VoiceRoomRealtimeKind.roomUpdate,
      'Oda sahibi: $name',
    );
  }

  void _applyRoomEventRoomClosed(Map<String, dynamic> payload) {
    final msg = payload['message']?.toString() ?? 'Oda kapatıldı';
    _postVoiceSessionEndSummary(endedLabel: msg);
    state = state.copyWith(
      error: msg,
      presence: const [],
      seatSlots: const [],
      selfInRoom: false,
      backendSyncReady: false,
      clearRoomTrtc: true,
    );
    _knownPresenceIds.clear();
    ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(false);
    unawaited(
      leaveRoomSession(
        source: 'sse_room_closed',
        awaitBackend: true,
        force: true,
      ),
    );
  }

  List<VoiceRoomSeatSlot> _patchSeatSlots(
    List<VoiceRoomSeatSlot> current, {
    required String userId,
    required int? newIndex,
    required int? previousIndex,
    String? occupantName,
    String? occupantImage,
  }) {
    final target = voiceRoomSeatMapTargetCount(
      configuredSeatCount: state.roomSeatCount ?? _roomMeta.seatCount,
      fromListLength: current.isEmpty ? null : current.length,
    );
    var slots = current.isNotEmpty
        ? List<VoiceRoomSeatSlot>.from(current)
        : List.generate(target, VoiceRoomSeatSlot.empty);
    while (slots.length < target) {
      slots.add(VoiceRoomSeatSlot.empty(slots.length));
    }
    if (previousIndex != null &&
        previousIndex >= 0 &&
        previousIndex < slots.length) {
      slots[previousIndex] = VoiceRoomSeatSlot.empty(previousIndex);
    }
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].userId == userId) {
        slots[i] = VoiceRoomSeatSlot.empty(i);
      }
    }
    if (newIndex != null && newIndex >= 0 && newIndex < slots.length) {
      slots[newIndex] = VoiceRoomSeatSlot(
        index: newIndex,
        userId: userId,
        name: occupantName,
        image: occupantImage,
      );
    }
    return slots;
  }

  void _clearSeatForUser(String userId) {
    if (state.seatSlots.isEmpty) return;
    final slots = List<VoiceRoomSeatSlot>.from(state.seatSlots);
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].userId == userId) {
        slots[i] = VoiceRoomSeatSlot.empty(i);
      }
    }
    state = state.copyWith(seatSlots: slots);
  }

  void _syncSeatMic(String userId, bool micOn) {
    if (state.seatSlots.isEmpty) return;
    final slots = List<VoiceRoomSeatSlot>.from(state.seatSlots);
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].userId == userId) {
        slots[i] = VoiceRoomSeatSlot(
          index: slots[i].index,
          userId: slots[i].userId,
          name: slots[i].name,
          image: slots[i].image,
          micOn: micOn,
        );
      }
    }
    state = state.copyWith(seatSlots: slots);
  }

  int? _parseEventInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  bool? _parseEventBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  /// PART4 SSE `seat_update` — koltuk listesini backend'den yeniler (300 ms debounce).
  void _scheduleSeatsRefreshFromBackend() {
    _seatRefreshDebounce?.cancel();
    _seatRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_refreshSeatsFromBackend());
    });
  }

  Future<void> _refreshSeatsFromBackend() async {
    if (_roomKey.isEmpty) return;
    try {
      final seats = await ref.read(chatRoomRemoteProvider).fetchSeats(
            _roomKey,
            alternateKey: _musicAlternateKey,
            targetSeatCount: state.roomSeatCount ?? _roomMeta.seatCount,
          );
      final hadOccupied =
          state.seatSlots.any((s) => (s.userId?.trim().isNotEmpty ?? false));
      final incomingOccupied =
          seats.any((s) => (s.userId?.trim().isNotEmpty ?? false));
      // Geçici boş yanıt koltuktan düşmeyi tetiklemesin.
      if (seats.isEmpty || (hadOccupied && !incomingOccupied)) {
        VoiceRoomDebugLog.log('sse.seat_update.skip_empty', {
          'room': _roomKey,
          'hadOccupied': hadOccupied,
          'incomingCount': seats.length,
        });
        return;
      }
      final nextPresence = _syncPresenceSeatIndexFromSlots(
        state.presence,
        seats,
      );
      state = state.copyWith(seatSlots: seats, presence: nextPresence);
      VoiceRoomDebugLog.log('sse.seat_update.refresh', {
        'room': _roomKey,
        'count': seats.length,
      });
    } on Object catch (e) {
      VoiceRoomDebugLog.log('sse.seat_update.fail', {'error': e.toString()});
    }
  }

  /// Koltuk haritası otoriter — presence.seatIndex yalnızca slot'ta görününce güncellenir.
  List<ChatRoomPresence> _syncPresenceSeatIndexFromSlots(
    List<ChatRoomPresence> presence,
    List<VoiceRoomSeatSlot> slots,
  ) {
    if (slots.isEmpty) return presence;
    final seatByUser = <String, int>{};
    for (final slot in slots) {
      final uid = slot.userId?.trim() ?? '';
      if (uid.isNotEmpty && slot.index >= 0) {
        seatByUser[uid] = slot.index;
      }
    }
    if (seatByUser.isEmpty) return presence;

    final selfId = ref.read(authControllerProvider).valueOrNull?.id;
    var changed = false;
    final next = <ChatRoomPresence>[];
    for (final p in presence) {
      final fromSlot = seatByUser[p.id];
      if (fromSlot == null) {
        // Kendi koltuğunu geçici boş yanıtta koru (yetki/internet dışı düşme yok).
        if (selfId != null &&
            p.id == selfId &&
            p.seatIndex != null &&
            slots.any((s) => (s.userId?.trim().isNotEmpty ?? false))) {
          next.add(p);
          continue;
        }
        next.add(p);
        continue;
      }
      if (p.seatIndex == fromSlot) {
        next.add(p);
        continue;
      }
      changed = true;
      next.add(
        ChatRoomPresence(
          id: p.id,
          name: p.name,
          nickname: p.nickname,
          image: p.image,
          chatRole: p.chatRole,
          roleSymbol: p.roleSymbol,
          membership: p.membership,
          seatIndex: fromSlot,
          isSpeaking: p.isSpeaking,
          isMuted: p.isMuted,
          micOn: p.micOn,
        ),
      );
    }
    return changed ? next : presence;
  }
}
