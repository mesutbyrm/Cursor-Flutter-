import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/agora/data/datasources/agora_remote_datasource.dart';
import '../../features/agora/domain/entities/agora_credentials.dart';
import '../../features/agora/presentation/providers/agora_providers.dart';
import '../../features/live/domain/entities/voice_room_entity.dart';
import '../../features/trtc/domain/entities/trtc_credentials.dart';
import '../../features/trtc/presentation/providers/trtc_providers.dart';
import '../../features/voice_hub/presentation/audio/voice_room_music_audio_session.dart';
import '../providers/auth_selectors.dart';

/// Sesli oda girişi — UI ≤1 sn; Agora token + ses arka planda hazırlanır.
abstract final class VoiceRoomEntryPerf {
  static const entryBudget = Duration(seconds: 1);
  static const tokenCacheTtl = Duration(minutes: 3);

  static final Map<String, _TrtcCacheEntry> _trtcCache = {};
  static final Map<String, _AgoraCacheEntry> _agoraCache = {};

  /// Liste dokunuşu / VIP kapısı — navigasyondan önce çağırın.
  static void prewarmOnRoomTap(WidgetRef ref, VoiceRoomEntity room) {
    unawaited(VoiceRoomMusicAudioSession.ensureConfigured());
    unawaited(_prefetchTrtc(ref, room));
    unawaited(_prefetchAgora(ref, room));
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
    if (DateTime.now().difference(entry.at) > tokenCacheTtl) return null;
    return entry.cred;
  }

  static AgoraCredentials? takeAgora({
    required String userId,
    required String roomId,
    String role = 'audience',
  }) {
    final key = _agoraCacheKey(userId, roomId, role);
    final entry = _agoraCache.remove(key);
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > tokenCacheTtl) return null;
    return entry.cred;
  }

  @visibleForTesting
  static void testPutTrtc({
    required String userId,
    required String roomId,
    required TrtcCredentials cred,
  }) {
    _trtcCache[_cacheKey(userId, roomId)] =
        _TrtcCacheEntry(cred, DateTime.now());
  }

  @visibleForTesting
  static void testPutAgora({
    required String userId,
    required String roomId,
    required AgoraCredentials cred,
    String role = 'audience',
  }) {
    _agoraCache[_agoraCacheKey(userId, roomId, role)] =
        _AgoraCacheEntry(cred, DateTime.now());
  }

  static String _cacheKey(String userId, String roomId) =>
      '${userId.trim()}:${roomId.trim()}';

  static String _agoraCacheKey(String userId, String roomId, String role) =>
      '${userId.trim()}:${roomId.trim()}:${role.trim()}';

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
        DateTime.now().difference(existing.at) <= tokenCacheTtl) {
      return;
    }

    try {
      final remote = ref.read(trtcRemoteProvider);
      TrtcCredentials cred;
      try {
        cred = await remote.fetchToken(roomId: roomId, role: 'audience');
      } catch (_) {
        cred = await remote.fetchUserSig(userId: userId, roomId: roomId);
      }
      _trtcCache[key] = _TrtcCacheEntry(cred, DateTime.now());
    } catch (_) {}
  }

  static Future<void> _prefetchAgora(
    WidgetRef ref,
    VoiceRoomEntity room,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    final roomId = room.apiRoomKey.isNotEmpty
        ? room.apiRoomKey.trim()
        : room.id.trim();
    if (userId == null || userId.isEmpty || roomId.isEmpty) return;

    for (final role in const ['audience', 'host']) {
      final key = _agoraCacheKey(userId, roomId, role);
      final existing = _agoraCache[key];
      if (existing != null &&
          DateTime.now().difference(existing.at) <= tokenCacheTtl) {
        continue;
      }
      try {
        final cred = await ref
            .read(agoraRemoteProvider)
            .fetchVoiceRoomToken(roomId: roomId, role: role);
        _agoraCache[key] = _AgoraCacheEntry(cred, DateTime.now());
      } catch (_) {}
    }
  }
}

class _TrtcCacheEntry {
  _TrtcCacheEntry(this.cred, this.at);

  final TrtcCredentials cred;
  final DateTime at;
}

class _AgoraCacheEntry {
  _AgoraCacheEntry(this.cred, this.at);

  final AgoraCredentials cred;
  final DateTime at;
}
