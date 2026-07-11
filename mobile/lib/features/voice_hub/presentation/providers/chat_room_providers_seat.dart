part of 'chat_room_providers.dart';

/// Sesli oda koltuk/mikrofon-sırası API'si — [VoiceRoomLiveController]'dan ayrıldı.
/// `part of` — aynı kütüphane; private erişim ve davranış birebir korunur.
extension VoiceRoomSeatControls on VoiceRoomLiveController {
  int? _privilegedRolePriority(
    UserEntity user,
    ChatRoomMyPermissions? server,
    ChatRoomPresence? self,
  ) {
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
    final err = await assignSeat(seatIndex: seatIndex, userId: user.id);
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

  Future<String?> assignSeat({required int seatIndex, String? userId}) async {
    try {
      await ref
          .read(voiceSeatRestServiceProvider)
          .takeSeat(_roomKey, seatIndex, userId: userId);
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> clearUserSeat({required String userId}) async {
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
}
