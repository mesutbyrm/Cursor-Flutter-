part of 'chat_room_providers.dart';

// Extension methods on Notifier access `state` in the same library.
// Analyzer still flags @protected/@visibleForTesting across extensions.
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Sesli oda "presence motoru" — katıl/ayrıl, heartbeat, presence merge,
/// mikrofon değişimi, giriş duyuruları/bannerları. [VoiceRoomLiveController]'dan
/// ayrıldı. `part of` — aynı kütüphane: private ALANLAR (ör. _knownPresenceIds,
/// _presenceJoined, _presenceHeartbeat) ana sınıfta kalır; bu extension onlara
/// okuma/yazma erişir ve davranış birebir korunur. Public applyPresenceSnapshot
/// bilerek ana sınıfta bırakıldı.
extension VoiceRoomPresenceEngine on VoiceRoomLiveController {
  bool _markEntranceOnce(String raw) {
    final key = VoiceOfficialJoin.entranceDedupeKey(raw, roomName: _roomMeta.nameTr);
    if (_shownEntranceKeys.contains(key)) return false;
    _shownEntranceKeys.add(key);
    return true;
  }

  void _syncPresenceJoinAnnouncements(List<ChatRoomPresence> merged) {
    if (!_entrancesArmed) {
      final nextIds = merged.map((p) => p.id).where((id) => id.isNotEmpty).toSet();
      _knownPresenceIds
        ..clear()
        ..addAll(nextIds);
      for (final p in merged) {
        if (p.id.isEmpty) continue;
        final n = p.displayName.trim().isNotEmpty
            ? p.displayName.trim()
            : p.name.trim();
        if (n.isNotEmpty) _lastKnownPresenceNames[p.id] = n;
      }
      return;
    }
    final previous = _knownPresenceIds;
    final nextIds = merged.map((p) => p.id).where((id) => id.isNotEmpty).toSet();
    if (previous.isEmpty) {
      _knownPresenceIds
        ..clear()
        ..addAll(nextIds);
      return;
    }
    for (final user in merged) {
      if (user.id.isEmpty || previous.contains(user.id)) continue;
      _announcePresenceJoin(user);
    }
    // Ayrılanlar — poll ile (SSE gelmese de) herkes çıkışı görsün.
    final departedIds = previous.difference(nextIds);
    if (departedIds.isNotEmpty) {
      final self = ref.read(authControllerProvider).valueOrNull?.id;
      for (final id in departedIds) {
        if (id.isEmpty || id == self) continue;
        final name = _lastKnownPresenceNames[id];
        if (name != null && name.isNotEmpty) {
          final line = '$name odadan çıkış yaptı.';
          _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.leave, line);
          _appendSyntheticSystemMessage(
            line,
            kind: ChatMessageKind.systemLeave,
            user: ChatRoomUserRef(id: id, name: name),
          );
        }
      }
    }
    for (final p in merged) {
      if (p.id.isEmpty) continue;
      final n = p.displayName.trim().isNotEmpty
          ? p.displayName.trim()
          : p.name.trim();
      if (n.isNotEmpty) _lastKnownPresenceNames[p.id] = n;
    }
    _knownPresenceIds
      ..clear()
      ..addAll(nextIds);
  }

  void _announcePresenceJoin(ChatRoomPresence user) {
    final name = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : user.name.trim();
    if (name.isEmpty) return;
    final userRef = ChatRoomUserRef(
      id: user.id,
      name: user.name,
      nickname: user.nickname,
      image: user.image,
      chatRole: user.chatRole,
    );
    if (VoiceStaffChatStyle.isStaffEntry(content: name, user: userRef)) {
      final staffLine = VoiceStaffChatStyle.formatStaffEntryLine(
        name,
        user: userRef,
        roomName: _roomMeta.nameTr,
      );
      _pushRealtimeEvent(VoiceRoomRealtimeKind.join, staffLine);
      _appendSyntheticSystemMessage(
        '$name odaya giriş yaptı.',
        kind: ChatMessageKind.systemJoin,
        user: userRef,
      );
      _showStaffEnterBanner(name, user: userRef);
      return;
    }
    final line = '$name giriş yaptı';
    _pushRealtimeEvent(VoiceRoomRealtimeKind.join, line);
    _appendSyntheticSystemMessage(
      '$name odaya giriş yaptı.',
      kind: ChatMessageKind.systemJoin,
      user: userRef,
    );
    final banner = VoiceOfficialJoin.formatEntranceBanner(
      line,
      roomName: _roomMeta.nameTr,
    );
    if (banner.isEmpty || !_markEntranceOnce(banner)) return;
    state = state.copyWith(enterBanner: banner);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 10), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  void _showStaffEnterBanner(String name, {ChatRoomUserRef? user}) {
    final line = VoiceStaffChatStyle.formatStaffEntryLine(
      name,
      user: user,
      roomName: _roomMeta.nameTr,
    );
    if (!_markEntranceOnce(line)) return;
    state = state.copyWith(enterBanner: line);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 10), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  List<ChatRoomPresence> _mergeSelf(List<ChatRoomPresence> list) {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return list;
    if (list.any((p) => p.id == user.id)) return list;
    return [
      ...list,
      ChatRoomPresence(
        id: user.id,
        name: user.display,
        nickname: user.username,
        image: user.avatarUrl,
        chatRole: user.role ?? 'listener',
        roleSymbol: _roleSymbolForUser(user),
      ),
    ];
  }

  List<ChatRoomPresence> _mergePresenceStable(
    List<ChatRoomPresence> incoming, {
    required String source,
  }) {
    final previous = state.presence;
    final withSelf = _mergeSelf(incoming);
    if (withSelf.isEmpty && previous.isNotEmpty) {
      VoiceRoomDebugLog.presenceUpdate(
        roomId: _roomKey,
        previousCount: previous.length,
        incomingCount: 0,
        mergedCount: previous.length,
        source: '$source.keep_previous',
      );
      return previous;
    }
    final prevById = <String, ChatRoomPresence>{
      for (final p in previous) p.id: p,
    };
    final merged = <ChatRoomPresence>[];
    for (final p in withSelf) {
      final prev = prevById[p.id];
      if (prev == null) {
        merged.add(p);
        continue;
      }
      merged.add(
        ChatRoomPresence(
          id: p.id,
          name: p.name.trim().isNotEmpty ? p.name : prev.name,
          nickname: (p.nickname?.trim().isNotEmpty == true)
              ? p.nickname
              : prev.nickname,
          image: (p.image?.trim().isNotEmpty == true) ? p.image : prev.image,
          chatRole: (p.chatRole?.trim().isNotEmpty == true)
              ? p.chatRole!
              : (prev.chatRole ?? 'listener'),
          roleSymbol: p.roleSymbol ?? prev.roleSymbol,
          membership: p.membership ?? prev.membership,
          seatIndex: p.seatIndex ?? prev.seatIndex,
          isSpeaking: p.isSpeaking || prev.isSpeaking,
          isMuted: p.isMuted,
        ),
      );
    }
    VoiceRoomDebugLog.presenceUpdate(
      roomId: _roomKey,
      previousCount: previous.length,
      incomingCount: withSelf.length,
      mergedCount: merged.length,
      source: source,
    );
    final seatCount = merged.where((p) => p.seatIndex != null).length;
    if (seatCount > 0) {
      VoiceRoomDebugLog.seatUpdate(
        roomId: _roomKey,
        seatCount: seatCount,
        source: source,
      );
    }
    return merged;
  }

  void _detectMicChanges(List<ChatRoomPresence> next) {
    final prev = {for (final p in state.presence) p.id: p.isSpeaking};
    for (final p in next) {
      final was = prev[p.id];
      if (was == null || was == p.isSpeaking) continue;
      final name = p.displayName.trim().isNotEmpty
          ? p.displayName.trim()
          : p.name.trim();
      if (name.isEmpty) continue;
      _pushRealtimeEvent(
        p.isSpeaking ? VoiceRoomRealtimeKind.micOn : VoiceRoomRealtimeKind.micOff,
        p.isSpeaking ? '$name konuşuyor' : '$name sustu',
      );
    }
  }

  void _patchHubPresenceCount(int count) {
    if (_roomKey.isEmpty) return;
    ref.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(_roomKey, count);
    final alt = _roomMeta.slug.trim();
    if (alt.isNotEmpty && alt != _roomKey) {
      ref.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(alt, count);
    }
  }

  Future<void> _broadcastStaffEntryIfNeeded() async {
    if (_roomKey.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    ChatRoomPresence? self;
    for (final p in state.presence) {
      if (p.id == user.id) {
        self = p;
        break;
      }
    }
    final userRef = ChatRoomUserRef(
      id: user.id,
      name: user.display,
      nickname: user.username,
      image: user.avatarUrl,
      chatRole: self?.chatRole,
    );
    if (!VoiceStaffChatStyle.isStaffEntry(
      content: '',
      user: userRef,
    ) &&
        !VoiceRoomPermissions.forUser(
          user: user,
          room: _roomMeta,
          selfPresence: self,
          server: state.serverPermissions,
        ).isSiteAdmin &&
        !VoiceRoomPermissions.forUser(
          user: user,
          room: _roomMeta,
          selfPresence: self,
          server: state.serverPermissions,
        ).canModerate) {
      return;
    }
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.username;
    final symbol = self?.roleSymbol?.trim() ?? '';
    try {
      await ref.read(chatRoomRemoteProvider).postEntryAnnouncement(
            roomKey: _roomKey,
            alternateKey: _roomMeta.slug,
            userName: name,
            roleSymbol: symbol.isNotEmpty ? symbol : null,
            entryType: VoiceStaffChatStyle.entryRoleLabel(userRef),
          );
    } catch (_) {}
  }

  Future<void> _joinPresence() async {
    if (_roomKey.isEmpty) {
      state = state.copyWith(loading: false, error: 'Geçersiz oda kimliği');
      return;
    }
    if (_presenceJoined && state.selfInRoom) {
      VoiceRoomDebugLog.roomJoin(
        roomId: _roomKey,
        source: 'presence',
        skipped: true,
      );
      return;
    }
    VoiceRoomDebugLog.roomJoin(roomId: _roomKey, source: 'presence');
    try {
      final token = await ref.read(tokenStorageProvider).readAccess();
      final hasJwt = token != null && token.isNotEmpty;
      VoiceRoomDebugLog.jwtStatus(hasToken: hasJwt, tokenLength: token?.length);
      ref.read(voiceRoomDiagnosticProvider.notifier).setJwt(hasJwt: hasJwt);
      VoiceRoomDebugLog.log('api.presence.join', {'room': _roomKey});
      final user = ref.read(authControllerProvider).valueOrNull;
      final nick = _effectiveNickname(user);
      _presenceNickname = nick;
      final joined = await ref.read(chatRoomRemoteProvider).joinPresence(
            _roomKey,
            nickname: nick,
          );
      final merged = _mergeSelf(joined);
      VoiceRoomDebugLog.log('api.presence.join.ok', {
        'count': merged.length,
        'roomId': _roomKey,
      });
      _presenceJoined = true;
      state = state.copyWith(
        presence: _mergePresenceStable(merged, source: 'join'),
        selfInRoom: true,
        loading: false,
        clearError: true,
      );
      _knownPresenceIds
        ..clear()
        ..addAll(merged.map((p) => p.id).where((id) => id.isNotEmpty));
      _entrancesArmed = true;
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setPresence(joined: true, count: merged.length);
      _patchHubPresenceCount(merged.length);
      unawaited(_tryAutoPrivilegedSeat());
      unawaited(_broadcastStaffEntryIfNeeded());
    } on Object catch (e) {
      VoiceRoomDebugLog.log('api.presence.join.fail', {'error': e.toString()});
      ref.read(voiceRoomDiagnosticProvider.notifier).setPresence(joined: false);
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setError(ApiException.userMessage(e));
      final msg = ApiException.userMessage(e);
      if (msg.toLowerCase().contains('yasak') ||
          msg.contains('403') ||
          msg.toLowerCase().contains('forbidden')) {
        state = state.copyWith(
          loading: false,
          error: 'Bu odadan yasaklandınız',
        );
        return;
      }
      // Oda kısmen çalışıyorsa (optimistic presence) kritik olmayan join
      // hatalarını kalıcı banner yapma.
      if (state.selfInRoom || state.presence.isNotEmpty) {
        VoiceRoomDebugLog.log('api.presence.join.soft_fail', {'error': msg});
        state = state.copyWith(loading: false, clearError: true);
        return;
      }
      state = state.copyWith(
        loading: false,
        error: msg.contains('401') || msg.toLowerCase().contains('oturum')
            ? 'Listede görünmek için tekrar giriş yapın.'
            : msg,
      );
    }
  }

  Future<void> _leavePresence() async {
    if (_roomKey.isEmpty) return;
    // selfInRoom=true means join was acknowledged by backend; even if the
    // _presenceJoined flag wasn't set yet (race during room switch), still
    // send DELETE to avoid the user appearing in the old room.
    if (!_presenceJoined && !state.selfInRoom) return;
    _presenceJoined = false;
    try {
      await ref.read(chatRoomRemoteProvider).leavePresence(_roomKey);
    } catch (_) {}
  }

  void _removeSelfFromPresenceOptimistic() {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId == null || userId.isEmpty) return;
    final remaining =
        state.presence.where((p) => p.id != userId).toList(growable: false);
    if (remaining.length == state.presence.length) return;
    state = state.copyWith(presence: remaining, selfInRoom: false);
    _knownPresenceIds.remove(userId);
    _patchHubPresenceCount(remaining.length);
  }

  Future<void> _leavePresenceWithSeatClear() async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId != null && userId.isNotEmpty) {
      try {
        await ref.read(chatRoomRemoteProvider).clearSeat(
              roomKey: _roomKey,
              alternateKey: _musicAlternateKey,
              userId: userId,
            );
      } catch (_) {}
    }
    await _leavePresence();
  }

  Future<void> _presenceHeartbeatTick() async {
    if (_roomKey.isEmpty) return;
    final last = _lastSseEventAt;
    if (state.sseConnected &&
        last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 45)) {
      return;
    }
    try {
      VoiceRoomDebugLog.log('api.presence.heartbeat', {'room': _roomKey});
      await ref.read(chatRoomRemoteProvider).presenceHeartbeat(_roomKey);
    } catch (e) {
      VoiceRoomDebugLog.log('api.presence.heartbeat.fail', {
        'error': e.toString(),
      });
    }
  }

  List<ChatRoomPresence> _presenceFromSsePayload(Map<String, dynamic> payload) {
    dynamic raw = payload['users'] ?? payload['presence'] ?? payload['members'];
    if (raw == null && payload['user'] is Map) {
      raw = [payload['user']];
    }
    if (raw == null) {
      final userId = payload['userId']?.toString() ?? payload['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        raw = [payload];
      }
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  void _scanEntrancesFromMessages(
    List<ChatRoomMessage> previous,
    List<ChatRoomMessage> merged,
  ) {
    if (!_entrancesArmed || previous.isEmpty) return;
    final prevIds = previous.map((m) => m.id).toSet();
    for (final m in merged) {
      if (prevIds.contains(m.id)) continue;
      if (m.kind != ChatMessageKind.systemJoin) continue;
      if (VoiceStaffChatStyle.isStaffEntry(
        content: m.content,
        user: m.user,
      )) {
        continue;
      }
      _pushRealtimeEvent(VoiceRoomRealtimeKind.join, m.content.trim());
      if (!VoiceOfficialJoin.isEntranceWorthy(
        content: m.content,
        membership: m.user?.membership,
        chatRole: m.user?.chatRole,
      )) {
        continue;
      }
      if (_markEntranceOnce(m.content)) {
        _showEnterBanner(m.content);
      }
    }
  }

  void _showEnterBanner(String raw) {
    final formatted = VoiceOfficialJoin.formatEntranceBanner(
      raw,
      roomName: _roomMeta.nameTr,
    );
    if (formatted.isEmpty) return;
    state = state.copyWith(enterBanner: formatted);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 10), () {
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  ChatRoomPresence? _resolvePresence(String target) {
    final raw = target.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (raw.isEmpty) return null;
    for (final user in state.presence) {
      final keys = [
        user.id,
        user.name,
        user.nickname,
      ].whereType<String>().map((e) => e.trim().toLowerCase());
      if (keys.any((key) => key == raw || key.contains(raw))) return user;
    }
    return null;
  }
}
