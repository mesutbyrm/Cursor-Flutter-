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
  int? _extractOnlineCountFromPayload(Map<String, dynamic> payload) {
    for (final key in const [
      'onlineCount',
      'onlineUsers',
      'totalCount',
      'count',
      'participantCount',
    ]) {
      final v = payload[key];
      if (v is num && v >= 0) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null && n >= 0) return n;
      }
    }
    final nested = payload['room'];
    if (nested is Map) {
      return _extractOnlineCountFromPayload(Map<String, dynamic>.from(nested));
    }
    return null;
  }

  void _patchHubOnlineCountFromPayload(
    Map<String, dynamic> payload, {
    int? fallback,
  }) {
    final count = _extractOnlineCountFromPayload(payload) ?? fallback;
    if (count != null && count >= 0) {
      _patchHubPresenceCount(count);
    }
  }

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
          final banner = '👋 $name → $_roomLabelForBanner odasından çıkış yaptı';
          _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.leave, line);
          _appendSyntheticSystemMessage(
            line,
            kind: ChatMessageKind.systemLeave,
            user: ChatRoomUserRef(id: id, name: name),
          );
          _pushEnterExitBanner(banner);
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
      _pushEnterExitBanner('👋 $name → $_roomLabelForBanner odasına giriş yaptı');
      if (staffLine.isNotEmpty) {
        ref.read(staffEntranceMarqueeProvider.notifier).enqueue(
              staffLine,
              roomName: _roomMeta.nameTr,
            );
      }
      return;
    }
    final line = '$name giriş yaptı';
    _pushRealtimeEvent(VoiceRoomRealtimeKind.join, line);
    _appendSyntheticSystemMessage(
      '$name odaya giriş yaptı.',
      kind: ChatMessageKind.systemJoin,
      user: userRef,
    );
    final banner = '👋 $name → $_roomLabelForBanner odasına giriş yaptı';
    _pushEnterExitBanner(banner);
    // Gold / VIP → ek site geneli marquee (mevcut davranış).
    if (VoiceOfficialJoin.isEntranceWorthy(
      content: line,
      membership: user.membership,
      chatRole: user.chatRole,
    )) {
      final tierBanner = VoiceStaffChatStyle.formatTierEntranceLine(
        displayName: name,
        user: userRef,
        section: 'sesli odaya',
      );
      if (tierBanner.isNotEmpty) {
        ref.read(staffEntranceMarqueeProvider.notifier).enqueue(
              tierBanner,
              roomName: _roomMeta.nameTr,
            );
      }
    }
  }

  void _showStaffEnterBanner(String name, {ChatRoomUserRef? user}) {
    final line = VoiceStaffChatStyle.formatStaffEntryLine(
      name,
      user: user,
      roomName: _roomMeta.nameTr,
    );
    if (!_markEntranceOnce(line)) return;
    ref.read(staffEntranceMarqueeProvider.notifier).enqueue(line, roomName: _roomMeta.nameTr);
    state = state.copyWith(enterBanner: line);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 5), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  List<ChatRoomPresence> _mergePresenceStable(
    List<ChatRoomPresence> incoming, {
    required String source,
  }) {
    final previous = state.presence;
    final pollSource =
        source == 'refresh' || source == 'poll' || source == 'preload';

    if (pollSource && state.sseConnected) {
      VoiceRoomDebugLog.presenceUpdate(
        roomId: _roomKey,
        previousCount: previous.length,
        incomingCount: incoming.length,
        mergedCount: previous.length,
        source: '$source.skip_sse',
      );
      return previous;
    }

    if (pollSource && incoming.isEmpty && previous.isNotEmpty) {
      VoiceRoomDebugLog.presenceUpdate(
        roomId: _roomKey,
        previousCount: previous.length,
        incomingCount: 0,
        mergedCount: previous.length,
        source: '$source.keep_fetch_empty',
      );
      return previous;
    }

    final replaced = replacePresenceSnapshot(
      previous: previous,
      incoming: incoming,
    );
    VoiceRoomDebugLog.presenceUpdate(
      roomId: _roomKey,
      previousCount: previous.length,
      incomingCount: incoming.length,
      mergedCount: replaced.length,
      source: isPresenceReplaceSource(source) ? source : '$source.replace',
    );
    final seatCount = replaced.where((p) => p.seatIndex != null).length;
    if (seatCount > 0) {
      VoiceRoomDebugLog.seatUpdate(
        roomId: _roomKey,
        seatCount: seatCount,
        source: source,
      );
    }
    return replaced;
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
    if (count > _peakViewerCount) _peakViewerCount = count;
    if (_roomKey.isEmpty) return;
    state = state.copyWith(hubOnlineCount: count);
    final patched = <String>{};
    for (final key in _roomKeyAliases) {
      final k = key.trim();
      if (k.isEmpty || patched.contains(k)) continue;
      patched.add(k);
      ref.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(k, count);
    }
  }

  Future<void> _refreshHubOnlineCountFromServer() async {
    if (_presenceApiKey.isEmpty) return;
    try {
      final snapshot = await ref.read(chatRoomRemoteProvider).fetchRoomState(
            _presenceApiKey,
            alternateKey: _presenceAlternateKey,
          );
      if (snapshot.onlineCount != null) {
        _patchHubPresenceCount(snapshot.onlineCount!);
      }
    } catch (_) {}
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
    final name = user.display.trim().isNotEmpty
        ? user.display.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.username);
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
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
      try {
        await _joinPresenceAttempt();
        return;
      } on Object catch (e) {
        lastError = e;
        if (attempt < 2 && _isTransientPresenceJoinError(e)) {
          VoiceRoomDebugLog.log('api.presence.join.retry', {
            'room': _roomKey,
            'attempt': attempt + 1,
            'error': e.toString(),
          });
          continue;
        }
        break;
      }
    }
    if (lastError != null) {
      _handlePresenceJoinFailure(lastError);
    }
  }

  bool _isTransientPresenceJoinError(Object e) {
    final msg = ApiException.userMessage(e).toLowerCase();
    return msg.contains('zaman aşımı') ||
        msg.contains('timeout') ||
        msg.contains('sunucu yanıt vermedi') ||
        msg.contains('bağlantı kurulamadı') ||
        msg.contains('bağlantınızı kontrol');
  }

  Future<void> _joinPresenceAttempt() async {
    final token = await ref.read(tokenStorageProvider).readAccess();
      final hasJwt = token != null && token.isNotEmpty;
      VoiceRoomDebugLog.jwtStatus(hasToken: hasJwt, tokenLength: token?.length);
      ref.read(voiceRoomDiagnosticProvider.notifier).setJwt(hasJwt: hasJwt);
      VoiceRoomDebugLog.log('api.presence.join', {'room': _roomKey});
      final user = ref.read(authControllerProvider).valueOrNull;
      final nick = _effectiveNickname(user);
      _presenceNickname = nick;
      final pendingPass = ref
          .read(pendingRoomPasswordProvider.notifier)
          .peek(_roomKey);
      final joinSeat = peekJoinSeatIndexForPrivilegedUser();
      final joined = await ref.read(chatRoomRemoteProvider).joinPresence(
            _presenceApiKey,
            alternateKey: _presenceAlternateKey,
            nickname: nick,
            password: pendingPass,
            seatIndex: joinSeat,
          );
      ref.read(pendingRoomPasswordProvider.notifier).clear(_roomKey);
      VoiceRoomDebugLog.log('api.presence.join.ok', {
        'count': joined.length,
        'roomId': _roomKey,
      });
      _presenceJoined = true;
      final merged = _mergePresenceStable(joined, source: 'join');
      state = state.copyWith(
        presence: merged,
        selfInRoom: true,
        loading: false,
        clearError: true,
        hubOnlineCount: merged.length,
      );
      _knownPresenceIds
        ..clear()
        ..addAll(merged.map((p) => p.id).where((id) => id.isNotEmpty));
      _entrancesArmed = true;
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setPresence(joined: true, count: merged.length);
      _startPresenceHeartbeat();
      unawaited(refreshServerPermissions());
      unawaited(_broadcastStaffEntryIfNeeded());
  }

  void _handlePresenceJoinFailure(Object e) {
      VoiceRoomDebugLog.log('api.presence.join.fail', {'error': e.toString()});
      ref.read(voiceRoomDiagnosticProvider.notifier).setPresence(joined: false);
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setError(ApiException.userMessage(e));
      final msg = ApiException.userMessage(e);
      final lower = msg.toLowerCase();
      if (lower.contains('şifre') ||
          lower.contains('sifre') ||
          lower.contains('password') ||
          lower.contains('wrong password') ||
          lower.contains('invalid password') ||
          (e is ApiException && e.statusCode == 401)) {
        ref.read(pendingRoomPasswordProvider.notifier).clear(_roomKey);
        state = state.copyWith(
          loading: false,
          error: 'Oda şifresi hatalı. Şifreyi bilmeden giremezsiniz.',
        );
        return;
      }
      if (lower.contains('yasak') ||
          msg.contains('403') ||
          lower.contains('forbidden')) {
        state = state.copyWith(
          loading: false,
          error: 'Bu odadan yasaklandınız',
        );
        return;
      }
      // Oda kısmen çalışıyorsa (optimistic presence) kritik olmayan join
      // hatalarını kalıcı banner yapma.
      if (state.selfInRoom || state.presence.isNotEmpty || state.sseConnected) {
        VoiceRoomDebugLog.log('api.presence.join.soft_fail', {'error': msg});
        state = state.copyWith(loading: false, clearError: true);
        return;
      }
      if (lower.contains('invalid type') || lower.contains('geçersiz alan')) {
        state = state.copyWith(loading: false, clearError: true);
        return;
      }
      if (lower.contains('sunucu hatası') ||
          lower.contains('internal server') ||
          msg.contains('500')) {
        // Oda sahibi / katılımcı zaten içerideyse geçici 500 banner gösterme.
        if (state.selfInRoom || state.presence.isNotEmpty) {
          state = state.copyWith(loading: false, clearError: true);
          unawaited(refreshServerPermissions());
          return;
        }
      }
      state = state.copyWith(
        loading: false,
        error: msg.contains('401') || msg.toLowerCase().contains('oturum')
            ? 'Listede görünmek için tekrar giriş yapın.'
            : msg,
      );
  }

  Future<void> _leavePresence({bool force = false}) async {
    if (_roomKey.isEmpty) return;
    // selfInRoom=true means join was acknowledged by backend; even if the
    // _presenceJoined flag wasn't set yet (race during room switch), still
    // send leave to avoid the user appearing in the old room.
    if (!force && !_presenceJoined && !state.selfInRoom) return;
    _presenceJoined = false;
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = null;
    try {
      await ref.read(chatRoomRemoteProvider).leavePresence(
            _presenceApiKey,
            alternateKey: _presenceAlternateKey,
          );
    } catch (_) {}
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(
      ChatRoomRemoteDataSource.presenceHeartbeatInterval,
      (_) {
        if (!_sessionActive || !_presenceJoined || !state.selfInRoom) return;
        unawaited(_presenceHeartbeatTick());
      },
    );
  }

  void _removeSelfFromPresenceOptimistic() {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId == null || userId.isEmpty) return;
    final remaining =
        state.presence.where((p) => p.id != userId).toList(growable: false);
    if (remaining.length == state.presence.length) return;
    state = state.copyWith(
      presence: remaining,
      selfInRoom: false,
      hubOnlineCount: remaining.length,
    );
    _patchHubPresenceCount(remaining.length);
    _knownPresenceIds.remove(userId);
  }

  Future<void> _leavePresenceWithSeatClear({bool force = false}) async {
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
    await _leavePresence(force: force);
  }

  void _pushEnterExitBanner(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;
    if (!_markEntranceOnce(trimmed)) return;
    ref.read(staffEntranceMarqueeProvider.notifier).enqueue(
          trimmed,
          roomName: _roomMeta.nameTr,
        );
    state = state.copyWith(enterBanner: trimmed);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 5), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  String get _roomLabelForBanner {
    final name = _roomMeta.nameTr.trim();
    return name.isNotEmpty ? name : 'sesli oda';
  }

  void _syncDiscoverPresenceCount(int count) {
    if (_roomKey.isEmpty) return;
    final patched = <String>{};
    for (final key in _roomKeyAliases) {
      final k = key.trim();
      if (k.isEmpty || patched.contains(k)) continue;
      patched.add(k);
      ref.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(k, count);
    }
    _patchCachedRoom(
      (room) => room.copyWith(onlineCount: count, userCount: count),
    );
    _invalidateRoomCaches();
  }

  Future<void> _presenceHeartbeatTick() async {
    if (_roomKey.isEmpty) return;
    _presenceHeartbeatCount++;
    try {
      VoiceEventLog.heartbeat(roomId: _roomKey);
      VoiceRoomDebugLog.log('api.presence.heartbeat', {
        'room': _roomKey,
        'tick': _presenceHeartbeatCount,
      });
      await ref.read(chatRoomRemoteProvider).presenceHeartbeat(
            _presenceApiKey,
            alternateKey: _presenceAlternateKey,
          );
    } catch (e) {
      VoiceRoomDebugLog.log('api.presence.heartbeat.fail', {
        'error': e.toString(),
      });
    }
    final last = _lastSseEventAt;
    final sseSilent = last == null ||
        DateTime.now().difference(last) > const Duration(seconds: 45);
    if (!state.sseConnected) {
      unawaited(_preloadPresenceMembers());
    } else if (sseSilent) {
      unawaited(resyncAfterSseReconnect());
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
    return dedupePresencesById(
      raw
          .whereType<Map>()
          .map((e) {
            final map = Map<String, dynamic>.from(e);
            final canonical = canonicalPresenceIdFromJson(map);
            if (canonical.isNotEmpty && map['id']?.toString() != canonical) {
              map['id'] = canonical;
            }
            return ChatRoomPresence.fromJson(map);
          })
          .where((u) => u.id.isNotEmpty)
          .toList(),
    );
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
      final displayName = m.user?.displayName.trim().isNotEmpty == true
          ? m.user!.displayName.trim()
          : m.content.trim();
      final banner = m.user != null
          ? VoiceStaffChatStyle.formatTierEntranceLine(
              displayName: displayName,
              user: m.user,
            )
          : VoiceOfficialJoin.formatEntranceBanner(
              m.content,
              roomName: _roomMeta.nameTr,
            );
      if (banner.isNotEmpty && _markEntranceOnce(banner)) {
        _pushEntranceBanner(banner);
      }
    }
  }

  void _showEnterBanner(String raw) {
    final formatted = VoiceOfficialJoin.formatEntranceBanner(
      raw,
      roomName: _roomMeta.nameTr,
    );
    if (formatted.isEmpty || !_markEntranceOnce(formatted)) return;
    _pushEntranceBanner(formatted);
  }

  void _pushEntranceBanner(String banner) {
    ref.read(staffEntranceMarqueeProvider.notifier).enqueue(
          banner,
          roomName: _roomMeta.nameTr,
        );
    state = state.copyWith(enterBanner: banner);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 5), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  /// SSE `messages` — `[SYSTEM_JOIN]` / `[SYSTEM_VIP_JOIN:…]` giriş şeridi.
  void _handleSystemJoinEntrance(ChatRoomMessage msg) {
    final content = msg.content.trim();
    if (content.isEmpty) return;
    final user = msg.user;
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : content;

    if (VoiceStaffChatStyle.isStaffEntry(content: content, user: user)) {
      _showStaffEnterBanner(displayName, user: user);
      return;
    }

    if (!VoiceOfficialJoin.isEntranceWorthy(
      content: content,
      membership: user?.membership,
      chatRole: user?.chatRole,
    )) {
      return;
    }

    final banner = user != null
        ? VoiceStaffChatStyle.formatTierEntranceLine(
            displayName: displayName,
            user: user,
          )
        : VoiceOfficialJoin.formatEntranceBanner(
            content,
            roomName: _roomMeta.nameTr,
          );
    if (banner.isEmpty || !_markEntranceOnce(banner)) return;
    _pushEntranceBanner(banner);
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

  void _setPresenceMuted(String userId, bool muted) {
    if (userId.isEmpty) return;
    var changed = false;
    final updated = state.presence.map((p) {
      if (p.id != userId) return p;
      if (p.isMuted == muted) return p;
      changed = true;
      return ChatRoomPresence(
        id: p.id,
        name: p.name,
        nickname: p.nickname,
        image: p.image,
        chatRole: p.chatRole,
        roleSymbol: p.roleSymbol,
        membership: p.membership,
        seatIndex: p.seatIndex,
        isSpeaking: muted ? false : p.isSpeaking,
        isMuted: muted,
        micOn: muted ? false : p.micOn,
      );
    }).toList(growable: false);
    if (changed) {
      state = state.copyWith(presence: updated);
    }
  }
}
