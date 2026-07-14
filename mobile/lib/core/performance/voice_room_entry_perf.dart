import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/live/domain/entities/voice_room_entity.dart';
import '../../features/trtc/domain/entities/trtc_credentials.dart';
import '../../features/trtc/presentation/providers/trtc_providers.dart';
import '../../features/voice_hub/presentation/audio/voice_room_music_audio_session.dart';
import '../providers/auth_selectors.dart';

/// Sesli oda girişi — UI ≤1 sn; ses/TRTC arka planda hazırlanır.
abstract final class VoiceRoomEntryPerf {
  static const entryBudget = Duration(seconds: 1);
  static const trtcCacheTtl = Duration(minutes: 3);

  static final Map<String, _TrtcCacheEntry> _trtcCache = {};

  /// Liste dokunuşu / VIP kapısı — navigasyondan önce çağırın.
  static void prewarmOnRoomTap(WidgetRef ref, VoiceRoomEntity room) {
    unawaited(VoiceRoomMusicAudioSession.ensureConfigured());
    unawaited(_prefetchTrtc(ref, room));
  }

  /// Ana kabuk — AudioSession ilk oda girişinde bekletmesin.
  static void prewarmShell() {
    unawaited(VoiceRoomMusicAudioSession.ensureConfigured());
  }

  static TrtcCredentials? takeTrtc({
    required String userId,
    required String roomId,
  }) {
    final key = _cacheKey(userId, roomId);
    final entry = _trtcCache.remove(key);
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > trtcCacheTtl) return null;
    return entry.cred;
  }

  @visibleForTesting
  static void testPutTrtc({
    required String userId,
    required String roomId,
    required TrtcCredentials cred,
  }) {
    _trtcCache[_cacheKey(userId, roomId)] = _TrtcCacheEntry(cred, DateTime.now());
  }

  static String _cacheKey(String userId, String roomId) =>
      '${userId.trim()}:${roomId.trim()}';

  static Future<void> _prefetchTrtc(
    WidgetRef ref,
    VoiceRoomEntity room,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    final roomId = room.trtcRoomId.trim();
    if (userId == null || userId.isEmpty || roomId.isEmpty) return;

    final key = _cacheKey(userId, roomId);
    final existing = _trtcCache[key];
    if (existing != null &&
        DateTime.now().difference(existing.at) <= trtcCacheTtl) {
      return;
    }

    try {
      final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: userId,
            roomId: roomId,
          );
      _trtcCache[key] = _TrtcCacheEntry(cred, DateTime.now());
    } catch (_) {}
  }
}

class _TrtcCacheEntry {
  _TrtcCacheEntry(this.cred, this.at);

  final TrtcCredentials cred;
  final DateTime at;
}
