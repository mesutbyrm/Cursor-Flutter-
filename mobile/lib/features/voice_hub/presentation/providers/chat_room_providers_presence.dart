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
      // Immediately update local presence state (no delay)
      if (_sessionActive) {
        state = state.copyWith(presence: merged);
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
    final selfId = ref.read(authControllerProvider).valueOrNull?.id?.trim();
    for (final user in merged) {
      if (user.id.isEmpty || previous.contains(user.id)) continue;
      if (selfId != null && selfId.isNotEmpty && user.id == selfId) continue;
      _announcePresenceJoin(user);
    }
    // Ayrılanlar — poll ile (SSE gelmese de) herkes çıkışı görsün.
    var departedIds = previous.difference(nextIds);
    if (selfId != null && selfId.isNotEmpty && state.selfInRoom) {
      departedIds = departedIds.where((id) => id != selfId).toSet();
    }
    if (departedIds.isNotEmpty) {
      for (final id in departedIds) {
        if (id.isEmpty) continue;
        _markPresenceDeparted(id);
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
    if (selfId != null && selfId.isNotEmpty && state.selfInRoom) {
      _knownPresenceIds.add(selfId);
    }
  }

  void _announcePresenceJoin(ChatRoomPresence user) {
    if (user.id.isNotEmpty && _sessionAnnouncedJoinUserIds.contains(user.id)) {
      return;
    }
    final name = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : user.name.trim();
    if (name.isEmpty) return;
    if (user.id.isNotEmpty) {
      _sessionAnnouncedJoinUserIds.add(user.id);
    }
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
      return;
    }
    final isGoldOrVip = VoiceOfficialJoin.isEntranceWorthy(
      content: name,
      membership: user.membership,
      chatRole: user.chatRole,
    );
    final line = VoiceOfficialJoin.formatEntranceBanner(
      '$name odaya giriş yaptı',
    );
    _pushRealtimeEvent(VoiceRoomRealtimeKind.join, line);
    _appendSyntheticSystemMessage(
      '$name odaya giriş yaptı.',
      kind: ChatMessageKind.systemJoin,
      user: userRef,
    );
    if (isGoldOrVip) {
      final banner = '👋 $name → $_roomLabelForBanner odasına giriş yaptı';
      _pushEnterExitBanner(banner);
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

  void _markPresenceDeparted(String userId) => _presenceTombstone.mark(userId);

  List<ChatRoomPresence> _filterSelfWhenNotJoined(
    List<ChatRoomPresence> incoming,
  ) {
    if (_presenceJoined || state.selfInRoom) return incoming;
    final selfId = ref.read(authControllerProvider).valueOrNull?.id.trim();
    if (selfId == null || selfId.isEmpty) return incoming;
    return incoming
        .where((p) => p.id != selfId)
        .toList(growable: false);
  }

  List<ChatRoomPresence> _mergePresenceStable(
    List<ChatRoomPresence> incoming, {
    required String source,
  }) {
    if (!_sessionActive || _leaveInFlight) {
      VoiceRoomLifecycleTrace.callback(
        type: 'presence.merge',
        callbackRoomId: _roomKey,
        activeRoomId: null,
        accepted: false,
        generation: _liveSessionGeneration,
        disposed: true,
      );
      return List<ChatRoomPresence>.from(state.presence);
    }
    incoming = _presenceTombstone.filter(incoming);
    incoming = _filterSelfWhenNotJoined(incoming);
    final previous = List<ChatRoomPresence>.from(state.presence);
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

    if (source == 'sse' && incoming.isEmpty && previous.isNotEmpty) {
      VoiceRoomDebugLog.presenceUpdate(
        roomId: _roomKey,
        previousCount: previous.length,
        incomingCount: 0,
        mergedCount: previous.length,
        source: 'sse.keep_empty_snapshot',
      );
      return previous;
    }

    final replaced = replacePresenceSnapshot(
      previous: previous,
      incoming: incoming,
    );
    _purgeExpiredPendingSeatActions();
    final pendingGuarded = guardPresenceAgainstPendingSeatActions(
      merged: replaced,
      previous: previous,
      pendingByUser: _pendingSeatByUser,
    );
    // PK sırasında koltuk düşme koruması: PK aktif/pending iken sunucu koltuk
    // bilgisi taşımayan ("lighter") bir presence snapshot yollarsa mevcut
    // koltuklar korunur — kullanıcılar koltuktan düşüp kaybolmaz. Bu koruma
    // YALNIZCA PK sırasında ve tüm snapshot koltuksuzken devreye girer; normal
    // koltuk kalkma/oturma (snapshot koltuk taşıyorsa) etkilenmez.
    final guarded = _preserveSeatsDuringPk(
      merged: pendingGuarded,
      previous: previous,
    );
    _confirmPendingSeatFromSnapshot(guarded);

    VoiceRoomDebugLog.presenceUpdate(
      roomId: _roomKey,
      previousCount: previous.length,
      incomingCount: incoming.length,
      mergedCount: guarded.length,
      source: isPresenceReplaceSource(source) ? source : '$source.replace',
    );
    final seatCount = guarded.where((p) => p.seatIndex != null).length;
    if (seatCount > 0) {
      VoiceRoomDebugLog.seatUpdate(
        roomId: _roomKey,
        seatCount: seatCount,
        source: source,
      );
    }
    // Auto-seat yalnızca giriş / rol değişiminde; her SSE presence merge'de değil.
    if (source == 'join') {
      _maybeReconcileHostSeatIfNeeded();
    }
    return guarded;
  }

  /// PK aktif/pending iken koltuksuz snapshot mevcut koltukları düşürmesin.
  List<ChatRoomPresence> _preserveSeatsDuringPk({
    required List<ChatRoomPresence> merged,
    required List<ChatRoomPresence> previous,
  }) {
    final battle = ref.read(pkBattleRemoteProvider);
    final pkActive = battle != null &&
        !battle.isEnded &&
        (battle.isActive || battle.isPending);
    if (!pkActive) {
      // PK dışında koruma uygulanmıyor: `seatIndex` alanı "koltuk bilgisi yok"
      // ile "koltukta değil" durumunu ayırt etmediği için koruma genişletilirse
      // herkes kalktığında koltuklar kalıcı donabilir. Bu log, koltukların
      // düştüğü şikayetinde asıl nedenin koltuksuz snapshot olup olmadığını
      // cihaz kaydından doğrulamak için.
      final prevSeated = previous.where((p) => (p.seatIndex ?? -1) >= 0).length;
      if (prevSeated > 0 && !merged.any((p) => (p.seatIndex ?? -1) >= 0)) {
        VoiceRoomDebugLog.log('presence.seatless_snapshot', {
          'room': _roomKey,
          'previousSeated': prevSeated,
          'incoming': merged.length,
        });
      }
      return merged;
    }

    final incomingHasSeats = merged.any((p) => (p.seatIndex ?? -1) >= 0);
    if (incomingHasSeats) return merged;
    final prevSeatById = <String, int>{
      for (final p in previous)
        if ((p.seatIndex ?? -1) >= 0) p.id: p.seatIndex!,
    };
    if (prevSeatById.isEmpty) return merged;

    VoiceRoomDebugLog.log('presence.pk_seat_preserved', {
      'room': _roomKey,
      'seats': prevSeatById.length,
    });
    return [
      for (final p in merged)
        prevSeatById.containsKey(p.id)
            ? ChatRoomPresence(
                id: p.id,
                name: p.name,
                nickname: p.nickname,
                image: p.image,
                chatRole: p.chatRole,
                roleSymbol: p.roleSymbol,
                membership: p.membership,
                seatIndex: prevSeatById[p.id],
                isSpeaking: p.isSpeaking,
                isMuted: p.isMuted,
                micOn: p.micOn,
              )
            : p,
    ];
  }

  void _detectMicChanges(List<ChatRoomPresence> next) {
    final prev = {
      for (final p in List<ChatRoomPresence>.from(state.presence)) p.id: p.isSpeaking,
    };
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
    _scheduleRankingRefreshFromSse();
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

  Future<void> _joinPresence({bool rejoinAfterHeartbeat = false}) async {
    if (_roomKey.isEmpty) {
      state = state.copyWith(loading: false, error: 'Geçersiz oda kimliği');
      return;
    }
    // Idempotent: Prevent parallel join attempts (SSE reconnect + poll + etc.)
    if (!rejoinAfterHeartbeat && (_presenceJoined || state.selfInRoom)) {
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
        await _joinPresenceAttempt(
          allowSeatClaim: !rejoinAfterHeartbeat,
          rejoinAfterHeartbeat: rejoinAfterHeartbeat,
        );
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

  bool _shouldRejoinPresenceAfterHeartbeatFailure(Object e) {
    if (e is ApiException) {
      final code = e.statusCode;
      if (code == 401 || code == 403 || code == 404 || code == 410) {
        return true;
      }
      if (code != null && code >= 500) return false;
    }
    final msg = ApiException.userMessage(e).toLowerCase();
    return msg.contains('odada değil') ||
        msg.contains('not in room') ||
        (msg.contains('presence') && msg.contains('bulunamad'));
  }

  Future<void> _joinPresenceAttempt({
    bool allowSeatClaim = true,
    bool rejoinAfterHeartbeat = false,
  }) async {
    final token = await ref.read(tokenStorageProvider).readAccess();
      final hasJwt = token != null && token.isNotEmpty;
      VoiceRoomDebugLog.jwtStatus(hasToken: hasJwt, tokenLength: token?.length);
      ref.read(voiceRoomDiagnosticProvider.notifier).setJwt(hasJwt: hasJwt);
      VoiceRoomDebugLog.log('api.presence.join', {'room': _roomKey});
      final user = ref.read(authControllerProvider).valueOrNull;
      final nick = _effectiveNickname(user);
      _presenceNickname = nick;
      final accessToken =
          ref.read(roomAccessTokenProvider.notifier).peek(_roomKey);
      // Heartbeat sonrası yeniden katılımda koltuk talebi kapalıydı; sunucu
      // presence kaydını düşürdüyse kullanıcı odaya geri giriyor ama koltuğu
      // boş kalıyordu. Son doğrulanmış koltuk biliniyorsa geri istenir.
      final requestedSeat = rejoinAfterHeartbeat
          ? resolveRejoinSeatIndex(
              currentSeatIndex: _currentSelfSeatIndex(),
              lastConfirmedSeatIndex: _lastConfirmedSelfSeatIndex,
            )
          : (allowSeatClaim ? peekJoinSeatIndexForPrivilegedUser() : null);
      // Koltuk istenmiyorsa alan boş bırakılmaz: sunucu seatIndex gelmeyen
      // yeni girişte kullanıcıyı ilk boş koltuğa otomatik oturtuyor. -1
      // açıkça "dinleyici kal" demektir ve otomatik oturmayı engeller.
      final joinSeat = requestedSeat ?? -1;
      final joined = await ref.read(chatRoomRemoteProvider).joinPresence(
            _presenceApiKey,
            alternateKey: _presenceAlternateKey,
            nickname: nick,
            accessToken: accessToken,
            seatIndex: joinSeat,
          );
      // Şifreli odaya sunucu onayıyla giriş başarılı → bu oturum için kilidi aç.
      // Jeton saklı kalır: presence düşüp yeniden katılımda tekrar şifre sorulmaz.
      ref.read(vipUnlockedRoomsProvider.notifier).unlock(_roomKey);
      VoiceRoomDebugLog.log('api.presence.join.ok', {
        'count': joined.length,
        'roomId': _roomKey,
      });
      _presenceJoined = true;
      unawaited(_syncPendingJoinRequests());
      _selfPresenceTracker.reset();
      registerVoiceRoomLiveSession(
        ref,
        _presenceApiKey,
        aliases: _roomKeyAliases,
      );
      unawaited(
        VoiceRoomPresencePersistence.recordJoin(
          roomId: _presenceApiKey,
          alternateRoomId: _presenceAlternateKey,
          userId: user?.id,
        ),
      );
      _roomSessionManager?.syncHostJoined(reason: 'Backend presence join');
      final merged = _ensureSelfInPresenceList(
        _mergePresenceStable(joined, source: 'join'),
      );
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
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setPresence(joined: true, count: merged.length);
      _startPresenceHeartbeat();
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!_sessionActive) return;
        ref.read(livePkInviteSignalProvider.notifier).bump();
      });
      unawaited(refreshServerPermissions());
      unawaited(_refreshHubOnlineCountFromServer());
      if (allowSeatClaim) {
        _autoSeatAttempted = false;
        // Koltuk snapshot giriş sırasında `_beginRoomSession` içinde alınır;
        // burada ikinci `fetchSeats` yarışını ve gecikmeli oturmayı önler.
        _maybeReconcileHostSeatIfNeeded();
      }
  }

  List<ChatRoomPresence> _ensureSelfInPresenceList(
    List<ChatRoomPresence> merged,
  ) {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return merged;
    final nick = _effectiveNickname(user) ?? user.displayName ?? user.username;
    return augmentPresenceWithSelf(
      backendJoinAcknowledged: _presenceJoined,
      members: merged,
      self: ChatRoomPresence(
        id: user.id,
        name: nick,
        nickname: nick,
        chatRole: user.role,
      ),
    );
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
        ref.read(roomAccessTokenProvider.notifier).clear(_roomKey);
        ref.read(vipUnlockedRoomsProvider.notifier).lock(_roomKey);
        state = state.copyWith(
          loading: false,
          error: 'Oda şifresi doğrulanamadı. Odaya yeniden girin ve şifreyi tekrar girin.',
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

  /// Sunucudaki presence kaydını düşür.
  ///
  /// Dönüş: çıkış sunucu tarafından kabul edildi mi.
  ///
  /// İki kritik nokta:
  /// * İstemci [_presenceRemote] üzerinden okunur — bu metot `ref.onDispose`
  ///   içinden ateşle-unut çağrıldığında `ref.read` fırlatıyor ve istek hiç
  ///   gönderilmiyordu.
  /// * Kalıcı kayıt yalnızca çıkış **kabul edilince** silinir. Önceden
  ///   başarısız çıkışta da siliniyordu; böylece açılıştaki temizlik muhafızı
  ///   yeniden deneyecek bir kayıt bulamıyor ve kullanıcı sunucuda odada
  ///   kalmaya devam ediyordu.
  Future<bool> _leavePresence({bool force = false}) async {
    if (_roomKey.isEmpty) return false;
    // selfInRoom=true means join was acknowledged by backend; even if the
    // _presenceJoined flag wasn't set yet (race during room switch), still
    // send leave to avoid the user appearing in the old room.
    if (!force && !_presenceJoined && !state.selfInRoom) return false;
    _presenceJoined = false;
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = null;

    final apiKey = _presenceApiKey;
    final alternateKey = _presenceAlternateKey;
    final chat = _presenceRemote;
    LiveRoomRemoteDataSource? live = _liveRoomRemoteRef;
    if (live == null) {
      try {
        live = ref.read(liveRoomRemoteProvider);
      } catch (_) {}
    }
    String? userId;
    try {
      userId = ref.read(authControllerProvider).valueOrNull?.id;
    } catch (_) {}

    var cleared = false;
    if (chat != null && live != null) {
      cleared = await leaveVoiceRoomOnServerWithClients(
        chatRemote: chat,
        liveRemote: live,
        roomKey: apiKey,
        alternateKey: alternateKey,
        userId: userId,
      );
      if (!cleared && _roomKey.trim().isNotEmpty && _roomKey.trim() != apiKey) {
        cleared = await leaveVoiceRoomOnServerWithClients(
          chatRemote: chat,
          liveRemote: live,
          roomKey: _roomKey.trim(),
          alternateKey: _musicAlternateKey,
          userId: userId,
        );
      }
    }

    VoiceRoomDebugLog.log('api.presence.leave', {
      'room': apiKey,
      'accepted': cleared,
    });
    _roomSessionManager?.syncHostLeft(reason: 'Backend presence leave');
    if (cleared) {
      unawaited(VoiceRoomPresencePersistence.clearRoom(apiKey));
      if (alternateKey != null && alternateKey.isNotEmpty) {
        unawaited(VoiceRoomPresencePersistence.clearRoom(alternateKey));
      }
    }
    // Dispose sonrası `ref` kullanılamaz; çıkış isteği zaten gönderildi.
    try {
      if (ref.read(voiceRoomActiveLiveKeyProvider) == apiKey) {
        clearVoiceRoomLiveSession(ref, _roomKey);
      }
    } catch (_) {}
    return cleared;
  }

  void _startPresenceHeartbeat() {
    _startLiveMembershipHeartbeat();
  }

  /// Ağ geri geldiğinde sesli TRTC kanalı sessizce düşmüşse yeniden bağlan.
  /// TRTC `onConnectionLost` WiFi↔mobil data geçişinde her zaman tetiklenmez;
  /// bu, "sürekli odadan/koltuktan kopma" için istemci-tarafı yedektir. Koltuk
  /// (presence) sunucu durumu olduğundan TRTC yeniden bağlanması koltuğu düşürmez;
  /// ek olarak bir presence heartbeat tetiklenir ki sunucu düşürmesin.
  void _startNetworkRecoveryWatch() {
    unawaited(_networkRecoverySub?.cancel());
    _networkRecoverySub =
        ref.read(connectivityServiceProvider).onlineStream.listen((online) {
      // Notify manager of network state change
      _roomSessionManager?.onNetworkStateChanged(online);

      if (!online || !_sessionActive || !state.selfInRoom) return;
      final coordinator = ref.read(voiceRoomAudioCoordinatorProvider);
      if (coordinator.isReconnecting) return;
      VoiceRoomDebugLog.log('audio.trtc.network_recovery', {'room': _roomKey});
      unawaited(coordinator.ensureConnected());
      if (_presenceJoined) unawaited(_liveMembershipHeartbeatTick());
    });
  }

  void _announceSelfLeave() {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || user.id.isEmpty) return;
    final display = user.displayName?.trim() ?? '';
    final name = display.isNotEmpty
        ? display
        : (user.display.trim().isNotEmpty ? user.display.trim() : user.username);
    if (name.isEmpty) return;
    final userRef = ChatRoomUserRef(
      id: user.id,
      name: name,
      nickname: name,
      image: user.avatarUrl,
      chatRole: user.role,
    );
    final line = '$name çıkış yaptı';
    _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.leave, line);
    _appendSyntheticSystemMessage(
      '$name odadan çıkış yaptı.',
      kind: ChatMessageKind.systemLeave,
      user: userRef,
    );
  }

  void _removeSelfFromPresenceOptimistic() {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId == null || userId.isEmpty) return;
    _markPresenceDeparted(userId);
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

  Future<bool> _leavePresenceWithSeatClear({bool force = false}) async {
    String? userId;
    try {
      userId = ref.read(authControllerProvider).valueOrNull?.id;
    } catch (_) {
      userId = null;
    }
    if (userId != null && userId.isNotEmpty) {
      _clearSeatForUser(userId);
    }
    return _leavePresence(force: force);
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
    if (_roomKey.isEmpty || !_sessionActive || _leaveInFlight) return;
    if (_presenceHeartbeatInFlight) return;
    _presenceHeartbeatInFlight = true;
    _presenceHeartbeatCount++;
    // Heartbeat düşerse aynı koltuğa geri dönebilmek için önce hatırla.
    _rememberSelfSeatIfSeated();
    try {
      VoiceEventLog.heartbeat(roomId: _roomKey);
      VoiceRoomDebugLog.log('api.presence.heartbeat', {
        'room': _roomKey,
        'tick': _presenceHeartbeatCount,
      });
      // Anlık durum gönderilir: oturuyorsa kendi koltuğu, değilse -1.
      // (Son hatırlanan koltuk burada kullanılmaz; kullanıcı koltuktan
      // kendi kalktıysa heartbeat onu geri oturtmamalı.)
      final heartbeatSeat = _currentSelfSeatIndex() ?? -1;
      await ref.read(chatRoomRemoteProvider).presenceHeartbeat(
            _presenceApiKey,
            alternateKey: _presenceAlternateKey,
            seatIndex: heartbeatSeat,
          );
    } catch (e) {
      VoiceRoomDebugLog.log('api.presence.heartbeat.fail', {
        'error': e.toString(),
      });
      // Geçici ağ/5xx hatalarında yeniden join döngüsü koltuk düşürüyordu.
      if (_presenceJoined &&
          _sessionActive &&
          _shouldRejoinPresenceAfterHeartbeatFailure(e)) {
        _presenceJoined = false;
        unawaited(_joinPresence(rejoinAfterHeartbeat: true));
      }
    } finally {
      if (!_sessionActive || _leaveInFlight) {
        _presenceHeartbeatInFlight = false;
        return;
      }
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

  void _pushGoldTeamEntrance(ChatRoomUserRef? user, String displayName) {
    if (user == null) return;
    final tier = VipTier.fromMembership(user.membership);
    if (!tier.hasEntranceFx) return;
    final settings = ref.read(entranceEffectSettingsProvider);
    if (!entranceEffectAllowed(
      tier: tier,
      settings: settings,
      isStaff: false,
    )) {
      return;
    }
    final selfId = ref.read(authControllerProvider).valueOrNull?.id;
    final EntranceTheme theme;
    if (!settings.teamColorsEnabled) {
      theme = EntranceTheme.turkey;
    } else if (selfId != null && selfId == user.id) {
      theme = ref.read(myEntranceThemeProvider);
    } else {
      theme = entranceThemeFromUserJson({
        'favoriteTeam': user.favoriteTeam,
        if (user.teamRaw != null) 'team': user.teamRaw,
        'membership': user.membership,
      });
    }
    final roomKey = _roomKey;
    if (roomKey.isEmpty) return;
    ref.read(voiceRoomGoldEntranceProvider(roomKey).notifier).show(
          VoiceRoomGoldEntranceEvent(
            userName: displayName,
            tier: tier,
            theme: theme,
            avatarUrl: user.image,
          ),
          dedupeKey: '${user.id}:gold_team_entrance',
        );
  }

  void _pushEntranceBanner(String banner, {ChatRoomUserRef? user, String? displayName}) {
    if (user != null && displayName != null && displayName.isNotEmpty) {
      _pushGoldTeamEntrance(user, displayName);
    }
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
    _pushEntranceBanner(banner, user: user, displayName: displayName);
  }

  ChatRoomPresence? _resolvePresence(String target) {
    final raw = target.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (raw.isEmpty) return null;
    for (final user in List<ChatRoomPresence>.from(state.presence)) {
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

  /// Odadan çıkınca keşfet/ana sayfa sayacını sunucudan güncelle (0'a düşürme hatası).
  Future<void> _refreshDiscoverCountAfterLeave(String roomKey) async {
    if (roomKey.isEmpty) return;
    final keys = <String>{
      roomKey,
      _presenceApiKey,
      _presenceAlternateKey ?? '',
      _roomMeta.slug,
    }.where((k) => k.trim().isNotEmpty);
    for (final key in keys) {
      try {
        final snapshot = await ref.read(chatRoomRemoteProvider).fetchRoomState(
              key,
              alternateKey: _presenceAlternateKey,
            );
        final count = snapshot.onlineCount;
        if (count != null && count >= 0) {
          _syncDiscoverPresenceCount(count);
          return;
        }
      } catch (_) {}
    }
    unawaited(
      ref.read(voiceRoomsListNotifierProvider.notifier).refresh(),
    );
  }

  /// RoomSessionManager callback — presence join işlemi
  Future<void> _joinPresenceForManager() async {
    return _joinPresence();
  }

  /// RoomSessionManager callback — presence leave işlemi
  Future<void> _leavePresenceForManager() async {
    await _leavePresence(force: false);
  }

  /// RoomSessionManager callback — presence heartbeat
  Future<void> _presenceHeartbeatForManager() async {
    return _liveMembershipHeartbeatTick();
  }

  /// Host offline detection — oda sahibi çevrim dışı ise host koltuk boşalt
}
