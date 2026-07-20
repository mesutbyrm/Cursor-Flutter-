part of 'chat_room_providers.dart';

// Extension methods on Notifier access `state` in the same library.
// Analyzer still flags @protected/@visibleForTesting across extensions.
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Sesli oda koltuk/mikrofon-sırası API'si — [VoiceRoomLiveController]'dan ayrıldı.
/// `part of` — aynı kütüphane; private erişim ve davranış birebir korunur.
extension VoiceRoomSeatControls on VoiceRoomLiveController {
  int? _privilegedRolePriority(
    UserEntity user,
    ChatRoomMyPermissions? server,
    ChatRoomPresence? self,
  ) {
    final staff = ref.read(staffAccessProvider);
    if (staff.isFounder) {
      return VoiceRoomSeatPriority.tierAdmin;
    }

    if (server != null) {
      if (server.isGlobalAdmin) return VoiceRoomSeatPriority.tierAdmin;
      if (server.isRoomOwner || server.canGiveFounder) {
        return VoiceRoomSeatPriority.tierFounder;
      }
      if (server.canGiveSop) return VoiceRoomSeatPriority.tierSop;
      if (server.canGiveOp ||
          server.canMuteUsers ||
          server.canKickUsers ||
          server.canManageRoom) {
        return VoiceRoomSeatPriority.tierOp;
      }
      final serverSym = server.role?.trim();
      if (serverSym != null && serverSym.isNotEmpty) {
        final symTier = VoiceRoomSeatPriority.tierFromRoleSymbol(serverSym);
        if (symTier != null) return symTier;
      }
    }

    final symbol = self?.roleSymbol ?? _roleSymbolForUser(user);
    final symTier = VoiceRoomSeatPriority.tierFromRoleSymbol(symbol);
    if (symTier != null) return symTier;

    final tier = VoiceRoomSeatPriority.forUser(
      user,
      room: _roomMeta,
      self: self,
      server: server,
    );
    if (!VoiceRoomSeatPriority.shouldAutoSit(tier)) return null;
    return tier;
  }

  int? _pickAutoSeatIndex({
    required int myPriority,
    required List<ChatRoomPresence> presence,
  }) {
    return VoiceRoomSeatPriority.pickAutoSeatIndex(
      myTier: myPriority,
      presence: presence,
      room: _roomMeta,
    );
  }

  Future<void> _tryAutoPrivilegedSeat() async {
    if (_roomKey.isEmpty || !state.selfInRoom) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    ChatRoomPresence? self;
    for (final p in state.presence) {
      if (p.id == user.id) {
        self = p;
        break;
      }
    }
    if (self?.seatIndex != null) {
      _autoSeatAttempted = true;
      return;
    }

    final priority = _privilegedRolePriority(
      user,
      state.serverPermissions,
      self,
    );
    if (priority == null) return;
    if (_autoSeatAttempted) {
      ChatRoomPresence? selfNow;
      for (final p in state.presence) {
        if (p.id == user.id) {
          selfNow = p;
          break;
        }
      }
      if (selfNow?.seatIndex != null) return;
      _autoSeatAttempted = false;
    }

    final seatIndex = _pickAutoSeatIndex(
      myPriority: priority,
      presence: state.presence,
    );
    if (seatIndex == null) return;

    VoiceRoomDebugLog.log('seat.auto_join', {
      'room': _roomKey,
      'seat': seatIndex,
      'priority': priority,
    });
    // Manuel "Koltuğa Al" ile AYNI çalışan yolu kullan (voiceSeatRestService
    // .takeSeat). Eski joinSeat ucu 200 dönüp koltuğa oturtmuyordu; bu yüzden
    // yetkili otomatik koltuğa geçmiyordu.
    final err = await assignSeat(seatIndex: seatIndex);
    if (err == null) {
      _autoSeatAttempted = true;
      return;
    }
    // İzinler veya presence gecikirse bir sonraki poll'da tekrar dene.
    for (final p in state.presence) {
      if (p.id == user.id && p.seatIndex != null) {
        _autoSeatAttempted = true;
        break;
      }
    }
    if (self?.seatIndex == null) {
      _autoSeatAttempted = false;
    }
  }

  Future<String?> requestSpeak() async {
    try {
      await ref.read(chatRoomRemoteProvider).requestSpeak(_roomKey);
      ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(true);
      return null;
    } catch (e) {
      final msg = ApiException.userMessage(e);
      if (msg.contains('404')) {
        return 'Mikrofon isteği bu odada desteklenmiyor; boş koltuğa dokunarak oturmayı deneyin.';
      }
      return msg;
    }
  }

  Future<String?> cancelSpeakRequest() async {
    try {
      await ref.read(chatRoomRemoteProvider).cancelSpeakRequest(_roomKey);
      ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(false);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<List<String>> fetchSpeakRequests() async {
    try {
      return await ref.read(chatRoomRemoteProvider).fetchSpeakRequests(_roomKey);
    } catch (_) {
      return [];
    }
  }

  Future<String?> approveSpeakRequest(String userId) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .approveSpeakRequest(_roomKey, userId);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  /// Mikrofon açmadan önce boş koltuğa otur (normal kullanıcılar için).
  Future<bool> ensureSelfOnSeatForMic() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return false;
    for (final p in state.presence) {
      if (p.id == user.id && p.seatIndex != null) return true;
    }
    final seatIndex = VoiceRoomSeatPriority.pickAutoSeatIndex(
      myTier: VoiceRoomSeatPriority.tierNormal,
      presence: state.presence,
      room: _roomMeta,
    );
    if (seatIndex == null) return false;
    final err = await assignSeat(seatIndex: seatIndex);
    return err == null;
  }

  Future<String?> assignSeat({required int seatIndex, String? userId}) async {
    final targetId =
        (userId ?? ref.read(authControllerProvider).valueOrNull?.id)?.trim();
    if (targetId != null && targetId.isNotEmpty) {
      _applyOptimisticSeat(userId: targetId, seatIndex: seatIndex);
    }
    try {
      await ref
          .read(voiceSeatRestServiceProvider)
          .takeSeat(_roomKey, seatIndex, userId: userId);
      unawaited(refresh());
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  void _applyOptimisticSeat({
    required String userId,
    required int seatIndex,
  }) {
    final next = state.presence.map((p) {
      if (p.id != userId) {
        // Aynı koltuktaki başka kullanıcıyı boşalt.
        if (p.seatIndex == seatIndex) {
          return ChatRoomPresence(
            id: p.id,
            name: p.name,
            nickname: p.nickname,
            image: p.image,
            chatRole: p.chatRole,
            roleSymbol: p.roleSymbol,
            membership: p.membership,
            seatIndex: null,
            isSpeaking: p.isSpeaking,
            isMuted: p.isMuted,
          );
        }
        return p;
      }
      return ChatRoomPresence(
        id: p.id,
        name: p.name,
        nickname: p.nickname,
        image: p.image,
        chatRole: p.chatRole,
        roleSymbol: p.roleSymbol,
        membership: p.membership,
        seatIndex: seatIndex,
        isSpeaking: p.isSpeaking,
        isMuted: p.isMuted,
      );
    }).toList();
    if (!next.any((p) => p.id == userId)) return;
    state = state.copyWith(presence: next);
  }

  Future<String?> clearUserSeat({required String userId}) async {
    final prev = [
      for (final p in state.presence)
        if (p.id == userId)
          ChatRoomPresence(
            id: p.id,
            name: p.name,
            nickname: p.nickname,
            image: p.image,
            chatRole: p.chatRole,
            roleSymbol: p.roleSymbol,
            membership: p.membership,
            seatIndex: null,
            isSpeaking: false,
            isMuted: p.isMuted,
          )
        else
          p,
    ];
    state = state.copyWith(presence: prev);
    try {
      await ref.read(chatRoomRemoteProvider).clearSeat(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<void> _autoSeatAfterRoleGrant(String userId) async {
    final occupied = <int>{
      for (final p in state.presence)
        if (p.seatIndex != null) p.seatIndex!,
    };
    int? freeSeat;
    for (var seat = 0; seat <= 14; seat++) {
      if (!occupied.contains(seat)) {
        freeSeat = seat;
        break;
      }
    }
    if (freeSeat == null) return;
    final err = await assignSeat(seatIndex: freeSeat, userId: userId);
    if (err != null) return;
    try {
      await ref.read(chatRoomRemoteProvider).unmuteUser(
            roomKey: _roomKey,
            userId: userId,
          );
    } catch (_) {}
  }
}
