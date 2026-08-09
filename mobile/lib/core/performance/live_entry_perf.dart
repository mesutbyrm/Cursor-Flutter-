import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/live/domain/entities/live_stream_entity.dart';
import '../../features/live/presentation/providers/live_providers.dart';
import '../../features/trtc/domain/entities/trtc_credentials.dart';
import '../../features/trtc/presentation/providers/trtc_providers.dart';
import '../providers/auth_selectors.dart';
import 'network_perf.dart';

/// Canlı yayın girişi — ilk kare ASAP; TRTC/REST arka planda hazırlanır.
abstract final class LiveEntryPerf {
  static const firstFrameBudget = Duration(seconds: 2);
  static const trtcCacheTtl = Duration(minutes: 3);

  static final Map<String, _TrtcCacheEntry> _trtcCache = {};

  /// Liste dokunuşu — navigasyondan hemen önce.
  static void prewarmOnStreamTap(WidgetRef ref, LiveStreamEntity stream) {
    if (!stream.isLive) return;
    final streamId = stream.id.trim();
    if (streamId.isEmpty) return;
    unawaited(_prefetchTrtc(ref, streamId, 'audience'));
    unawaited(_prefetchJoin(ref, streamId));
  }

  static TrtcCredentials? takeTrtc({
    required String userId,
    required String streamId,
  }) {
    final key = _cacheKey(userId, streamId);
    final entry = _trtcCache.remove(key);
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > trtcCacheTtl) return null;
    return entry.cred;
  }

  @visibleForTesting
  static void testPutTrtc({
    required String userId,
    required String streamId,
    required TrtcCredentials cred,
  }) {
    _trtcCache[_cacheKey(userId, streamId)] =
        _TrtcCacheEntry(cred, DateTime.now());
  }

  static String _cacheKey(String userId, String streamId) =>
      '${userId.trim()}:${streamId.trim()}';

  static Future<void> _prefetchTrtc(
    WidgetRef ref,
    String streamId,
    String role,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) return;

    final key = _cacheKey(userId, streamId);
    final existing = _trtcCache[key];
    if (existing != null &&
        DateTime.now().difference(existing.at) <= trtcCacheTtl) {
      return;
    }

    try {
      final remote = ref.read(trtcRemoteProvider);
      final cred = await remote.fetchToken(
        roomId: streamId,
        role: role,
        userId: userId,
      );
      _trtcCache[key] = _TrtcCacheEntry(cred, DateTime.now());
    } catch (_) {}
  }

  static Future<void> _prefetchJoin(WidgetRef ref, String streamId) async {
    try {
      await ref.read(liveRemoteProvider).joinVideoStream(streamId);
    } catch (_) {}
  }

  static Future<TrtcCredentials> fetchTrtcParallel({
    required WidgetRef ref,
    required String streamId,
    required String role,
    required String userId,
  }) async {
    return NetworkPerf.parallel<TrtcCredentials>([
      () async {
        final cached = takeTrtc(userId: userId, streamId: streamId);
        if (cached != null) return cached;
        final remote = ref.read(trtcRemoteProvider);
        return remote.fetchToken(roomId: streamId, role: role, userId: userId);
      }(),
    ]).then((list) => list.first);
  }
}

class _TrtcCacheEntry {
  _TrtcCacheEntry(this.cred, this.at);

  final TrtcCredentials cred;
  final DateTime at;
}
