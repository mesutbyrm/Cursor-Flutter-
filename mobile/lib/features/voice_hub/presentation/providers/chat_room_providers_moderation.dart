part of 'chat_room_providers.dart';

// Extension methods on Notifier access `state` in the same library.
// Analyzer still flags @protected/@visibleForTesting across extensions.
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Sesli oda moderasyon API'si — [VoiceRoomLiveController]'dan ayrıldı.
/// `part of` — aynı kütüphane; private erişim ve davranış birebir korunur.
extension VoiceRoomModerationControls on VoiceRoomLiveController {
  Future<String?> postModeratorAnnouncement(String message) async =>
      sendDuyuruAnnouncement(message);

  bool _looksLikeDuyuruCommand(String trimmed) {
    final lower = trimmed.toLowerCase();
    return lower.startsWith('!duyuru') || lower.startsWith('/duyuru');
  }

  Future<String?> clearChatAsModerator() async {
    final perms = _permissions();
    if (!perms.canModerate && !perms.isRoomOwner) {
      return 'Sohbet temizleme yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).clearChatViaModeration(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
          );
      _applyLocalChatClear();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<ModerationKickResult?> kickUserModeration({
    required String userId,
    String? reason,
  }) async {
    final perms = _permissions();
    if (!perms.canModerate && !perms.isRoomOwner) return null;
    try {
      return await ref.read(chatRoomRemoteProvider).kickUser(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
            reason: reason,
          );
    } catch (_) {
      return null;
    }
  }

  Future<String?> banUserModeration({
    required String userId,
    String? reason,
  }) async {
    final perms = _permissions();
    if (!perms.canBanUsers && !perms.isRoomOwner) {
      return 'Ban yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).banUser(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
            reason: reason,
          );
      showModerationToast('Kullanıcı banlandı');
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> unbanUserModeration({required String userId}) async {
    final perms = _permissions();
    if (!perms.canBanUsers && !perms.isRoomOwner) {
      return 'Ban kaldırma yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).unbanUser(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
          );
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> unmuteUserModeration({required String userId}) async {
    final perms = _permissions();
    if (!perms.canMuteUsers && !perms.isRoomOwner && !perms.canModerate) {
      return 'Susturma kaldırma yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).unmuteUser(
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

  Future<List<String>> fetchBannedWords() async {
    try {
      final words =
          await ref.read(chatRoomRemoteProvider).fetchBannedWords(_roomKey);
      state = state.copyWith(bannedWords: words);
      return words;
    } catch (_) {
      return state.bannedWords;
    }
  }

  Future<List<VoiceRoomBanEntry>> fetchModerationBans() async {
    try {
      final snap = await ref.read(chatRoomRemoteProvider).fetchModeration(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
          );
      return snap.bans;
    } catch (_) {
      return const [];
    }
  }

  Future<String?> addBannedWord(String word) async {
    try {
      final words = await ref
          .read(chatRoomRemoteProvider)
          .addBannedWord(roomKey: _roomKey, word: word);
      state = state.copyWith(bannedWords: words);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeBannedWord(String word) async {
    try {
      final words = await ref
          .read(chatRoomRemoteProvider)
          .removeBannedWord(roomKey: _roomKey, word: word);
      state = state.copyWith(bannedWords: words);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }
}
